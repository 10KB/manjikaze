#!/bin/bash
# Runs the checks that CI runs on every pull request.
# Usage: checks/run.sh [check...]
# Checks: syntax shellcheck references configs swaync migrations (default: all of them)
set -e

cd "$(dirname "$(readlink -f "$0")")/.."

all_checks=(syntax shellcheck references configs swaync migrations)

# Tracked Bash scripts: *.sh files, and the files in bin/ with a Bash shebang.
shell_scripts() {
    git ls-files '*.sh'
    git ls-files bin | while read -r file; do
        if head -n 1 "$file" | grep -q '^#!/bin/bash'; then
            echo "$file"
        fi
    done
}

check_syntax() {
    local file failed=0
    while read -r file; do
        bash -n "$file" || failed=1
    done < <(shell_scripts)
    return "$failed"
}

check_shellcheck() {
    # Many scripts are sourced fragments without a shebang, so the shell is given explicitly.
    shell_scripts | xargs shellcheck --shell=bash --severity=error
}

# Every Manjikaze file that a script sources and every menu module has to exist.
check_references() {
    local file line path failed=0
    while IFS=: read -r file line path; do
        if [[ ! -e $path ]]; then
            echo "$file:$line: $path does not exist"
            failed=1
        fi
    done < <(
        shell_scripts | xargs grep -H -n -o -E '(source|\.) "\$MANJIKAZE_DIR/[^"$]+"' |
            sed -E 's#^([^:]+):([0-9]+):(source|\.) "\$MANJIKAZE_DIR/([^"]+)"$#\1:\2:\4#'
        grep -n -o -E 'load_module [^"]+"' lib/menus.sh |
            sed -E 's#^([0-9]+):load_module ([^"]+)"$#lib/menus.sh:\1:app/\2#'
    )
    return "$failed"
}

check_configs() {
    local luac file failed=0
    python3 checks/configs.py || failed=1

    luac=$(command -v luac5.4 || command -v luac || true)
    if [[ -z $luac ]]; then
        echo "luac not found; install Lua to check the Lua configuration."
        return 1
    fi
    while read -r file; do
        "$luac" -p "$file" || failed=1
    done < <(git ls-files '*.lua')
    return "$failed"
}

check_swaync() {
    python3 checks/swaync.py configs/swaync/config.json
}

# Migrations run in the order of their timestamps and are recorded by file name.
check_migrations() {
    local file name stamp first failed=0
    declare -A seen=()
    while read -r file; do
        name=$(basename "$file")
        # The first migration predates descriptive names.
        if [[ ! $name =~ ^[0-9]{10}_[a-z0-9_]+\.sh$ && $name != 1743535632.sh ]]; then
            echo "$file: name it <unix timestamp>_<description>.sh, in lowercase with underscores"
            failed=1
        fi
        stamp=${name%%[_.]*}
        if [[ -n ${seen[$stamp]} ]]; then
            echo "$file: timestamp $stamp is also used by ${seen[$stamp]}"
            failed=1
        fi
        seen[$stamp]=$file
        if [[ $(head -n 1 "$file") != "#!/bin/bash" ]]; then
            echo "$file: start with #!/bin/bash"
            failed=1
        fi
        first=$(grep -v -E '^[[:space:]]*(#|$)' "$file" | head -n 1)
        if [[ $first != "set -e" ]]; then
            echo "$file: the first command must be set -e"
            failed=1
        fi
    done < <(git ls-files 'migrations/*')
    return "$failed"
}

checks=("$@")
if [[ ${#checks[@]} -eq 0 ]]; then
    checks=("${all_checks[@]}")
fi

failed=()
for check in "${checks[@]}"; do
    if ! declare -F "check_$check" >/dev/null; then
        echo "Unknown check: $check (available: ${all_checks[*]})"
        exit 2
    fi
    echo "==> $check"
    if ! "check_$check"; then
        failed+=("$check")
    fi
done

if [[ ${#failed[@]} -gt 0 ]]; then
    echo "Failed: ${failed[*]}"
    exit 1
fi
echo "All checks passed."
