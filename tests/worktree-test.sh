#!/bin/bash
# The git worktree helpers wta and wtd from configs/zsh/manjikaze.zsh.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

command -v zsh > /dev/null || fail "zsh is installed"

export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com

REPO="$TEST_TMP/project"

# A repository with one commit on main, and no answers given to gum yet.
new_repo() {
    unset GUM_PICK GUM_CONFIRM
    rm -rf "$TEST_TMP"/project* "$TEST_TMP/origin.git" "$TEST_TMP"/gum.*
    git init -q -b main "$REPO"
    mkdir -p "$REPO/sub"
    echo one > "$REPO/sub/file"
    git -C "$REPO" add -A
    git -C "$REPO" commit -qm one
}

# Runs a helper in zsh from the given directory. The last line of the output is where it ended.
helpers() {
    local dir=$1
    shift
    zsh -f -c 'source "$1"; cd "$2" || exit 1; shift 2; "$@"; code=$?; print -r -- "$PWD"; exit $code' \
        zsh "$ROOT/configs/zsh/manjikaze.zsh" "$dir" "$@"
}

ended_in() {
    tail -n 1 "$TEST_TMP/out"
}

has_branch() {
    git -C "$REPO" show-ref --verify --quiet "refs/heads/$1"
}

new_repo
run helpers "$REPO/sub" wta feature/login
[[ $exit_code -eq 0 ]] || fail "wta creates a worktree" "$(errors)"
[[ $(ended_in) == "$REPO--feature-login" ]] || fail "wta goes to ../<repository>--<branch>, with a / in the branch as -" "$(output)"
[[ $(git -C "$REPO--feature-login" branch --show-current) == feature/login ]] || fail "the worktree is on the new branch"
pass "wta creates a branch and its worktree next to the repository, also from a subdirectory"

git -C "$REPO" branch existing
run helpers "$REPO--feature-login" wta existing
[[ $exit_code -eq 0 && $(ended_in) == "$REPO--existing" ]] || fail "wta checks out a branch that exists" "$(output)$(errors)"
pass "wta checks out an existing branch, also when it runs in another worktree"

git clone -q --bare "$REPO" "$TEST_TMP/origin.git"
git -C "$TEST_TMP/origin.git" branch remote-only main
git -C "$REPO" remote add origin "$TEST_TMP/origin.git"
git -C "$REPO" fetch -q origin
run helpers "$REPO" wta remote-only
[[ $exit_code -eq 0 ]] || fail "wta creates a worktree for a branch on origin" "$(errors)"
[[ $(git -C "$REPO--remote-only" rev-parse --abbrev-ref '@{upstream}') == origin/remote-only ]] ||
    fail "the branch tracks the one on origin"
pass "wta checks out a branch that only exists on origin, tracking it"

new_repo
helpers "$REPO" wta finished > /dev/null 2>&1
export GUM_CONFIRM=yes
run helpers "$REPO--finished/sub" wtd
[[ $exit_code -eq 0 && $(ended_in) == "$REPO" ]] || fail "wtd ends in the main checkout" "$(output)$(errors)"
[[ ! -e $REPO--finished ]] || fail "wtd removes the worktree"
! has_branch finished || fail "wtd deletes the merged branch"
pass "wtd removes a clean worktree and its merged branch"

new_repo
helpers "$REPO" wta dirty > /dev/null 2>&1
echo change > "$REPO--dirty/new-file"
export GUM_CONFIRM="yes no"
run helpers "$REPO--dirty" wtd
[[ -e $REPO--dirty/new-file ]] || fail "wtd keeps a worktree with changes unless you confirm"
has_branch dirty || fail "wtd keeps the branch of a worktree it didn't remove"
pass "wtd keeps a worktree with uncommitted changes unless you confirm"

new_repo
helpers "$REPO" wta unmerged > /dev/null 2>&1
echo two > "$REPO--unmerged/sub/file"
git -C "$REPO--unmerged" commit -qam two
export GUM_CONFIRM="yes no"
run helpers "$REPO--unmerged" wtd
[[ ! -e $REPO--unmerged ]] || fail "wtd removes a clean worktree"
has_branch unmerged || fail "wtd keeps a branch with unmerged commits unless you confirm"
rm "$TEST_TMP/gum.calls"
helpers "$REPO" wta unmerged > /dev/null 2>&1
export GUM_CONFIRM=yes
run helpers "$REPO--unmerged" wtd
! has_branch unmerged || fail "wtd deletes a branch with unmerged commits when you confirm"
pass "wtd keeps a branch with unmerged commits unless you confirm"

new_repo
export GUM_CONFIRM=yes
run helpers "$REPO" wtd
[[ $exit_code -ne 0 && -d $REPO/.git ]] || fail "wtd refuses the main checkout"
grep -q "main checkout can't be removed" "$TEST_TMP/err" || fail "wtd says why it refuses" "$(errors)"
pass "wtd refuses to remove the main checkout"

new_repo
helpers "$REPO" wta feature/x > /dev/null 2>&1
echo two > "$REPO--feature-x/sub/file"
git -C "$REPO--feature-x" commit -qam two
export GUM_CONFIRM=yes
run helpers "$REPO--feature-x" wt feature/x
[[ $exit_code -eq 0 && $(ended_in) == "$REPO" ]] || fail "wt <branch> ends in the main checkout" "$(output)$(errors)"
[[ $(git -C "$REPO" branch --show-current) == feature/x ]] || fail "the main checkout has the branch of the worktree"
[[ ! -e $REPO--feature-x ]] || fail "wt <branch> removes the worktree"
[[ $(< "$REPO/sub/file") == two ]] || fail "the main checkout has the commits of the worktree"
pass "wt <branch> checks out the branch of a worktree in the main checkout, and removes the worktree"

new_repo
helpers "$REPO" wta wip > /dev/null 2>&1
echo changed > "$REPO--wip/sub/file"
echo new > "$REPO--wip/new-file"
export GUM_CONFIRM=yes
run helpers "$REPO" wt wip
[[ $exit_code -eq 0 && $(git -C "$REPO" branch --show-current) == wip ]] || fail "wt <branch> takes over a worktree with changes" "$(output)$(errors)"
[[ $(< "$REPO/sub/file") == changed && $(< "$REPO/new-file") == new ]] || fail "wt <branch> takes uncommitted changes along"
[[ -z $(git -C "$REPO" stash list) ]] || fail "wt <branch> leaves no stash behind"
pass "wt <branch> takes the uncommitted changes of the worktree along"

new_repo
helpers "$REPO" wta other > /dev/null 2>&1
echo dirty > "$REPO/sub/file"
export GUM_CONFIRM=yes
run helpers "$REPO" wt other
[[ $exit_code -ne 0 && -d $REPO--other && $(git -C "$REPO" branch --show-current) == main ]] ||
    fail "wt <branch> changes nothing while the main checkout has changes" "$(output)$(errors)"
grep -q "Commit or stash them first" "$TEST_TMP/err" || fail "wt <branch> says why it stops" "$(errors)"
pass "wt <branch> refuses while the main checkout has uncommitted changes"

new_repo
git -C "$REPO" branch plain
run helpers "$REPO/sub" wt plain
[[ $exit_code -eq 0 && $(ended_in) == "$REPO" && $(git -C "$REPO" branch --show-current) == plain ]] ||
    fail "wt <branch> switches the main checkout to a branch without a worktree" "$(output)$(errors)"
pass "wt <branch> switches the main checkout to a branch without a worktree"

new_repo
export GUM_PICK=$'New worktree\nfeature/new'
run helpers "$REPO" wt
grep -q '^choose .*New worktree' "$TEST_TMP/gum.calls" && ! grep -q 'Go to a worktree' "$TEST_TMP/gum.calls" ||
    fail "without other worktrees, wt only offers a new one" "$(cat "$TEST_TMP/gum.calls")"
[[ $(ended_in) == "$REPO--feature-new" ]] || fail "wt creates a worktree for a branch name you type" "$(output)$(errors)"
pass "wt creates a worktree for a branch name you type"

new_repo
git -C "$REPO" branch free
git -C "$REPO" branch taken
helpers "$REPO" wta taken > /dev/null 2>&1
git clone -q --bare "$REPO" "$TEST_TMP/origin.git"
git -C "$TEST_TMP/origin.git" branch remote-only main
git -C "$REPO" remote add origin "$TEST_TMP/origin.git"
git -C "$REPO" fetch -q origin
export GUM_PICK=$'New worktree\nremote-only'
run helpers "$REPO" wt
[[ $(sort "$TEST_TMP/gum.options" | paste -sd ' ') == "free remote-only" ]] ||
    fail "wt offers the branches without a worktree, also those only on origin" "$(cat "$TEST_TMP/gum.options")"
[[ $(ended_in) == "$REPO--remote-only" ]] || fail "wt creates the worktree of the branch you pick" "$(output)$(errors)"
pass "wt offers the branches without a worktree, also those only on origin"

new_repo
helpers "$REPO" wta feature/a > /dev/null 2>&1
helpers "$REPO" wta feature/b > /dev/null 2>&1
export GUM_PICK=$'Go to a worktree\nfeature/b'
run helpers "$REPO--feature-a" wt
[[ $(sort "$TEST_TMP/gum.options" | paste -sd '|') == "feature/b|main (main checkout)" ]] ||
    fail "wt offers the other worktrees by their branch" "$(cat "$TEST_TMP/gum.options")"
[[ $(ended_in) == "$REPO--feature-b" ]] || fail "wt goes to the worktree you pick" "$(output)$(errors)"
pass "wt goes to another worktree, picked by its branch"

new_repo
helpers "$REPO" wta old > /dev/null 2>&1
export GUM_PICK=$'Remove a worktree\nold'
export GUM_CONFIRM=yes
run helpers "$REPO/sub" wt
[[ $exit_code -eq 0 && $(ended_in) == "$REPO/sub" ]] || fail "removing another worktree leaves you where you are" "$(output)$(errors)"
[[ ! -e $REPO--old ]] && ! has_branch old || fail "wt removes the worktree you pick and its branch"
! grep -q 'main checkout' "$TEST_TMP/gum.options" || fail "wt doesn't offer to remove the main checkout"
pass "wt removes the worktree you pick, also from elsewhere"

# A worktree registered the way a devcontainer that mounts the repository at /usr/src/app does.
container_worktree() {
    git -C "$REPO" worktree add -q -b "$1" "$REPO/.claude/worktrees/$1"
    echo "/usr/src/app/.claude/worktrees/$1/.git" > "$REPO/.git/worktrees/$1/gitdir"
    echo "gitdir: /usr/src/app/.git/worktrees/$1" > "$REPO/.claude/worktrees/$1/.git"
}

new_repo
container_worktree agent
echo agent > "$REPO/.claude/worktrees/agent/agent-file"
export GUM_PICK=$'Check out a worktree\'s branch\nagent (devcontainer)'
export GUM_CONFIRM=yes
run helpers "$REPO" wt
[[ $exit_code -eq 0 && $(git -C "$REPO" branch --show-current) == agent ]] ||
    fail "wt checks out the branch of a worktree made in a devcontainer" "$(output)$(errors)"
[[ ! -e $REPO/.claude/worktrees/agent && ! -e $REPO/.git/worktrees/agent ]] ||
    fail "wt removes the worktree made in a devcontainer and its registration"
[[ $(< "$REPO/agent-file") == agent ]] || fail "wt takes the changes of a worktree made in a devcontainer along"
pass "wt checks out the branch of a worktree made in a devcontainer, with its changes"

new_repo
container_worktree agent
export GUM_PICK=$'Go to a worktree\nagent (devcontainer)'
run helpers "$REPO" wt
[[ $(ended_in) == "$REPO/.claude/worktrees/agent" ]] || fail "wt goes to a worktree made in a devcontainer" "$(output)$(errors)"
grep -q "made in a devcontainer" "$TEST_TMP/err" || fail "wt says that git only works in the devcontainer" "$(errors)"
rm "$TEST_TMP/gum.calls"
export GUM_PICK=$'Remove a worktree\nagent (devcontainer)'
export GUM_CONFIRM=yes
run helpers "$REPO" wt
[[ ! -e $REPO/.claude/worktrees/agent ]] && ! has_branch agent || fail "wt removes a worktree made in a devcontainer" "$(output)$(errors)"
pass "wt goes to and removes a worktree made in a devcontainer"

new_repo
git -C "$REPO" worktree add -q -b gone "$REPO/.claude/worktrees/gone"
echo "/usr/src/app/.claude/worktrees/gone/.git" > "$REPO/.git/worktrees/gone/gitdir"
rm -r "$REPO/.claude/worktrees/gone"
run helpers "$REPO" wt gone
[[ $exit_code -ne 0 ]] && grep -q "doesn't exist here" "$TEST_TMP/err" ||
    fail "wt explains that a worktree's path doesn't exist here" "$(output)$(errors)"
pass "wt explains when the worktree of a branch doesn't exist here"

new_repo
helpers "$REPO" wta busy > /dev/null 2>&1
git -C "$REPO" worktree lock --reason "claude session busy (pid 1)" "$REPO--busy"
export GUM_CONFIRM="yes no"
run helpers "$REPO" wt busy
[[ -d $REPO--busy && $(git -C "$REPO" branch --show-current) == main ]] || fail "wt keeps a locked worktree unless you unlock it"
grep -q 'is locked: claude session busy (pid 1)' "$TEST_TMP/gum.calls" || fail "wt shows why the worktree is locked" "$(cat "$TEST_TMP/gum.calls")"
rm "$TEST_TMP/gum.calls"
export GUM_CONFIRM=yes
run helpers "$REPO" wt busy
[[ $exit_code -eq 0 && ! -e $REPO--busy && $(git -C "$REPO" branch --show-current) == busy ]] ||
    fail "wt unlocks a locked worktree and checks out its branch when you confirm" "$(output)$(errors)"
pass "wt unlocks a locked worktree only when you confirm"

new_repo
container_worktree agent
echo "claude session agent (pid 3283 start 1)" > "$REPO/.git/worktrees/agent/locked"
export GUM_PICK=$'Remove a worktree\nagent (devcontainer)'
export GUM_CONFIRM=yes
run helpers "$REPO" wt
[[ ! -e $REPO/.claude/worktrees/agent ]] && ! has_branch agent || fail "wt removes a locked worktree made in a devcontainer" "$(output)$(errors)"
pass "wt removes a locked worktree made in a devcontainer"
