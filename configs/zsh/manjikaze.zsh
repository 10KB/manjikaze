# Managed by Manjikaze, which replaces this file when it changes. Put your own settings in ~/.zshrc.

# Git worktrees, to work on several branches at once, for example with an agent in each.
# The names avoid ga, gd and gwt*, which oh-my-zsh's git plugin already uses.
#
#   wt              a menu to check out a worktree's branch, or to go to, create or remove a worktree
#   wt <branch>     make the branch the active one of the main checkout, taking over its worktree
#   wta <branch>    create a worktree for a branch at ../<repository>--<branch> and go there
#   wtd             remove the worktree you are in and its branch

# The main checkout, also from a subdirectory or another worktree.
_wt_main() {
    git worktree list --porcelain 2> /dev/null | sed -n '1s/^worktree //p'
}

# A worktree made in a devcontainer is registered with its path in the container, such as
# /usr/src/app/.claude/worktrees/x. This finds it below the main checkout here: the end of that path
# that exists here, with a .git file that points into the repository at the rest of the path.
_wt_from_container() {
    local dir=$1 main=$2 rest=$1 root
    while [[ $rest == /*/* ]]; do
        rest=/${rest#/*/}
        root=${dir%"$rest"}
        if [[ -f $main$rest/.git && $(< "$main$rest/.git") == "gitdir: $root/.git/"* ]]; then
            print -r -- "$main$rest"
            return 0
        fi
    done
    return 1
}

# Every worktree as <path><tab><where><tab><branch>. <where> is "here", "devcontainer" for a
# worktree made in a devcontainer and found here, or "missing". The branch is empty when detached.
_wt_list() {
    local main dir found branch
    main=$(_wt_main)
    git worktree list --porcelain | awk '
        /^worktree / { if (dir != "") print dir "\t" branch; dir = substr($0, 10); branch = "" }
        /^branch / { branch = substr($0, 8); sub(/^refs\/heads\//, "", branch) }
        END { if (dir != "") print dir "\t" branch }' |
        while IFS=$'\t' read -r dir branch; do
            if [[ -d $dir ]]; then
                print -r -- "$dir"$'\t'here$'\t'"$branch"
            elif found=$(_wt_from_container "$dir" "$main"); then
                print -r -- "$found"$'\t'devcontainer$'\t'"$branch"
            else
                print -r -- "$dir"$'\t'missing$'\t'"$branch"
            fi
        done
}

# Branches without a worktree: local ones, then the ones that are only on origin.
_wt_free_branches() {
    local branch
    local -a used
    used=(${(f)"$(_wt_list | cut -f3)"})
    {
        git for-each-ref --format='%(refname:short)' refs/heads
        git for-each-ref --format='%(refname:lstrip=3)' refs/remotes/origin | grep -vx HEAD
    } | awk '!seen[$0]++' | while read -r branch; do
        (( ${used[(Ie)$branch]} )) || print -r -- "$branch"
    done
}

# Lets you pick a worktree by its branch, leaving out the one given, and prints <path><tab><where>.
# For "take" it leaves out worktrees without a branch.
_wt_pick() {
    local header=$1 leave_out=$2 purpose=$3 main dir where branch label choice
    local -a labels picks
    main=$(_wt_main)
    while IFS=$'\t' read -r dir where branch; do
        [[ $dir == "$leave_out" || $where == missing ]] && continue
        [[ $purpose == take && -z $branch ]] && continue
        label=${branch:-"${dir:t} (detached)"}
        [[ $dir == "$main" ]] && label="$label (main checkout)"
        [[ $where == devcontainer ]] && label="$label (devcontainer)"
        labels+=("$label")
        picks+=("$dir"$'\t'"$where")
    done < <(_wt_list)

    choice=$(gum choose --header="$header" "${labels[@]}") || return 1
    print -r -- "${picks[${labels[(ie)$choice]}]}"
}

# Git here can't use a worktree made in a devcontainer: its .git file points to a path in the container.
_wt_cd() {
    cd "$1" || return 1
    if [[ $2 == devcontainer ]]; then
        print -u2 "wt: this worktree was made in a devcontainer, so git only works in there"
    fi
}

# The directory of a worktree in .git/worktrees, named by its .git file. That also works for a
# worktree made in a devcontainer, whose .git file has the path in the container.
_wt_admin() {
    local common gitdir
    common=$(git -C "$(_wt_main)" rev-parse --path-format=absolute --git-common-dir) || return 1
    gitdir=$(sed -n 's/^gitdir: //p' "$1/.git")
    print -r -- "$common/worktrees/${gitdir:t}"
}

# Runs git for a worktree through its directory in .git/worktrees, without changing it.
_wt_git() {
    local admin
    admin=$(_wt_admin "$1") || return 1
    git --git-dir="$admin" --work-tree="$1" "${@:2}"
}

# An agent session, such as Claude Code, locks the worktree it works in. Its process may run in a
# devcontainer, so it can't be checked from here: you confirm that the session is done with it.
_wt_confirm_unlock() {
    local admin reason
    admin=$(_wt_admin "$1") || return 1
    [[ -f $admin/locked ]] || return 0
    reason=$(< "$admin/locked")
    gum confirm "$1 is locked${reason:+: $reason}. A session that still works there loses its directory. Unlock it?"
}

_wt_unlock() {
    local admin
    admin=$(_wt_admin "$1") || return 1
    [[ -f $admin/locked ]] || return 0
    git -C "$(_wt_main)" worktree unlock "$1"
}

# Points the links of a worktree made in a devcontainer to the paths here, so git here can remove it.
# Only for a worktree that is about to go: in the devcontainer, git can't use it anymore.
_wt_repair() {
    [[ $2 == devcontainer ]] || return 0
    git -C "$(_wt_main)" worktree repair "$1" > /dev/null 2>&1
}

# Asks before it removes a worktree and its branch. Changes that aren't committed and commits that
# aren't merged are only thrown away when you confirm that too.
_wt_remove() {
    local dir=$1 where=${2:-here} main branch dirty
    main=$(_wt_main)
    if [[ -z $main ]]; then
        print -u2 "wt: not in a git repository"
        return 1
    fi
    if [[ -z $dir || $dir == "$main" ]]; then
        print -u2 "wt: the main checkout can't be removed, only a worktree"
        return 1
    fi
    branch=$(_wt_git "$dir" branch --show-current)
    dirty=$(_wt_git "$dir" status --porcelain)

    gum confirm "Remove the worktree $dir${branch:+ and the branch $branch}?" || return 0
    if [[ -n $dirty ]]; then
        gum confirm "$dir has changes that aren't committed. Remove it anyway?" || return 1
    fi
    _wt_confirm_unlock "$dir" || return 1

    _wt_repair "$dir" "$where" || return 1
    _wt_unlock "$dir" || return 1
    if [[ $PWD/ == "$dir"/* ]]; then
        cd "$main" || return 1
    fi
    git -C "$main" worktree remove ${dirty:+--force} "$dir" || return 1

    if [[ -n $branch ]] && ! git -C "$main" branch -d "$branch"; then
        gum confirm "$branch has commits that aren't merged. Delete the branch anyway?" || return 0
        git -C "$main" branch -D "$branch"
    fi
}

# Checks out the branch of a worktree in the main checkout and removes the worktree, so the main
# checkout, and a dev server that runs from it, gets its files. Changes that aren't committed come
# along through git stash, which all worktrees share.
_wt_take() {
    local dir=$1 where=$2 main branch dirty
    main=$(_wt_main)
    branch=$(_wt_git "$dir" branch --show-current)
    if [[ -z $branch ]]; then
        print -u2 "wt: $dir has no branch checked out"
        return 1
    fi
    # Untracked files, such as worktrees below it, don't stop a switch.
    if [[ -n $(git -C "$main" status --porcelain --untracked-files=no) ]]; then
        print -u2 "wt: the main checkout has changes that aren't committed. Commit or stash them first."
        return 1
    fi
    dirty=$(_wt_git "$dir" status --porcelain)

    gum confirm "Check out $branch in ${main:t} and remove its worktree?" || return 0
    if [[ -n $dirty ]]; then
        gum confirm "$dir has changes that aren't committed. Take them along?" || return 1
    fi
    _wt_confirm_unlock "$dir" || return 1

    _wt_repair "$dir" "$where" || return 1
    _wt_unlock "$dir" || return 1
    if [[ -n $dirty ]]; then
        git -C "$dir" stash push --include-untracked --quiet --message "wt: $branch" || return 1
    fi
    cd "$main" || return 1
    git worktree remove "$dir" || return 1
    git switch --quiet "$branch" || return 1
    if [[ -n $dirty ]] && ! git stash pop --quiet; then
        print -u2 "wt: the changes from the worktree are kept in git stash"
        return 1
    fi
}

# It checks out the branch when it exists here or on origin, and otherwise creates it from the
# current commit.
wta() {
    if [[ -z $1 ]]; then
        print -u2 "Usage: wta <branch>"
        return 1
    fi

    local branch=$1 main dir
    main=$(_wt_main)
    if [[ -z $main ]]; then
        print -u2 "wta: not in a git repository"
        return 1
    fi
    dir="$main--${branch//\//-}"

    if git show-ref --verify --quiet "refs/heads/$branch"; then
        git worktree add "$dir" "$branch" || return 1
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        git worktree add --track -b "$branch" "$dir" "origin/$branch" || return 1
    else
        git worktree add -b "$branch" "$dir" || return 1
    fi
    cd "$dir"
}

wtd() {
    _wt_remove "$(git rev-parse --show-toplevel 2> /dev/null)"
}

wt() {
    local main here dir where branch action others takeable
    main=$(_wt_main)
    if [[ -z $main ]]; then
        print -u2 "wt: not in a git repository"
        return 1
    fi

    if [[ -n $1 ]]; then
        IFS=$'\t' read -r dir where branch < <(_wt_list | awk -F '\t' -v branch="$1" '$3 == branch { print; exit }')
        if [[ -z $where ]]; then
            git -C "$main" switch --quiet "$1" && cd "$main"
        elif [[ $where == missing ]]; then
            print -u2 "wt: $1 is checked out at $dir, which doesn't exist here"
            return 1
        elif [[ $dir == "$main" ]]; then
            cd "$main"
        else
            _wt_take "$dir" "$where"
        fi
        return
    fi

    here=$(git rev-parse --show-toplevel)
    others=$(_wt_list | awk -F '\t' -v here="$here" '$2 != "missing" && $1 != here' | wc -l)
    takeable=$(_wt_list | awk -F '\t' -v main="$main" '$2 != "missing" && $1 != main && $3 != ""' | wc -l)
    local -a actions
    (( takeable )) && actions+=("Check out a worktree's branch")
    (( others )) && actions+=("Go to a worktree")
    actions+=("New worktree")
    (( $(_wt_list | wc -l) > 1 )) && actions+=("Remove a worktree")
    action=$(gum choose --header="Worktrees of ${main:t}" "${actions[@]}") || return 0

    case $action in
        "Check out a worktree's branch")
            IFS=$'\t' read -r dir where <<< "$(_wt_pick "Check out in ${main:t}" "$main" take)" &&
                [[ -n $dir ]] && _wt_take "$dir" "$where"
            ;;
        "Go to a worktree")
            IFS=$'\t' read -r dir where <<< "$(_wt_pick "Go to" "$here")" && [[ -n $dir ]] && _wt_cd "$dir" "$where"
            ;;
        "New worktree")
            branch=$(_wt_free_branches | gum filter --no-strict --header="New worktree" \
                --placeholder="Pick a branch, or type a new name") || return 0
            [[ -n $branch ]] && wta "$branch"
            ;;
        "Remove a worktree")
            IFS=$'\t' read -r dir where <<< "$(_wt_pick "Remove" "$main")" &&
                [[ -n $dir ]] && _wt_remove "$dir" "$where"
            ;;
    esac
}
