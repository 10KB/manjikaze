#!/bin/bash
# Sourced by every tests/*-test.sh: a scratch HOME, stubs for gum and sudo, and assertions.

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

TEST_TMP=$(mktemp -d -t manjikaze-test.XXXXXX)
trap 'rm -rf "$TEST_TMP"' EXIT
export TEST_TMP

# A desktop session exports these, and they would lead a test to the real home or state file.
unset XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME MANJIKAZE_DIR MANJIKAZE_DATA_DIR
export HOME="$TEST_TMP/home"
mkdir -p "$HOME" "$TEST_TMP/bin"
export PATH="$TEST_TMP/bin:$PATH"

# Every stub call is appended to $TEST_TMP/<command>.calls.
cat > "$TEST_TMP/bin/gum" << 'EOF'
#!/bin/bash
echo "$*" >> "$TEST_TMP/gum.calls"
case "$1" in
    log) echo "${*: -1}" >&2 ;;
    # GUM_CONFIRM answers every confirm, or each in turn ("yes no"); the last answer then repeats.
    confirm)
        read -ra answers <<< "${GUM_CONFIRM:-no}"
        asked=$(grep -c '^confirm' "$TEST_TMP/gum.calls")
        answer=${answers[asked - 1]:-${answers[-1]}}
        [[ $answer == yes ]]
        ;;
    # GUM_PICK answers choose, filter and input in turn, one line each. The options of the last
    # choose or filter go to $TEST_TMP/gum.options. choose fails when the answer isn't an option.
    choose | filter | input)
        options=()
        if [[ $1 == choose ]]; then
            for argument in "${@:2}"; do
                [[ $argument == --* ]] || options+=("$argument")
            done
        elif [[ $1 == filter ]]; then
            mapfile -t options
        fi
        [[ $1 == input ]] || printf '%s\n' "${options[@]}" > "$TEST_TMP/gum.options"

        mapfile -t answers <<< "${GUM_PICK:-}"
        asked=$(grep -cE '^(choose|filter|input)' "$TEST_TMP/gum.calls")
        answer=${answers[asked - 1]:-}
        if [[ -z $answer ]]; then
            exit 1
        fi
        if [[ $1 == choose ]] && ! printf '%s\n' "${options[@]}" | grep -qxF -- "$answer"; then
            echo "gum choose: $answer is not one of: ${options[*]}" >&2
            exit 1
        fi
        echo "$answer"
        ;;
esac
EOF

cat > "$TEST_TMP/bin/sudo" << 'EOF'
#!/bin/bash
echo "$*" >> "$TEST_TMP/sudo.calls"
EOF

chmod +x "$TEST_TMP/bin/gum" "$TEST_TMP/bin/sudo"

pass() {
    printf 'ok - %s\n' "$1"
}

# Ends the test file: later assertions would only report on state this failure already broke.
fail() {
    if [[ -n ${2:-} ]]; then
        printf '%s\n' "$2" >&2
    fi
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

# Runs a command and keeps its exit code in $exit_code, its output in $TEST_TMP/out and $TEST_TMP/err.
run() {
    exit_code=0
    "$@" > "$TEST_TMP/out" 2> "$TEST_TMP/err" < /dev/null || exit_code=$?
}

output() {
    cat "$TEST_TMP/out"
}

errors() {
    cat "$TEST_TMP/err"
}
