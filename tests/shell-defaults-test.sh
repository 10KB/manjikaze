#!/bin/bash
# Manjikaze keeps its zsh file in the custom directory of oh-my-zsh up to date.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

MANJIKAZE="$TEST_TMP/manjikaze"
CUSTOM="$HOME/.oh-my-zsh/custom"

mkdir -p "$MANJIKAZE/bin" "$MANJIKAZE/configs" "$MANJIKAZE/migrations"
cp "$ROOT/bin/manjikaze" "$MANJIKAZE/bin/"
cp -r "$ROOT/lib" "$MANJIKAZE/"
cp -r "$ROOT/configs/zsh" "$MANJIKAZE/configs/"

run "$MANJIKAZE/bin/manjikaze" migrate --pending
[[ ! -e $HOME/.oh-my-zsh ]] || fail "without oh-my-zsh, Manjikaze creates nothing for it"
pass "Manjikaze leaves a workstation without oh-my-zsh alone"

mkdir -p "$CUSTOM"
run "$MANJIKAZE/bin/manjikaze" migrate --pending
cmp -s "$ROOT/configs/zsh/manjikaze.zsh" "$CUSTOM/manjikaze.zsh" ||
    fail "Manjikaze puts its zsh file in the custom directory of oh-my-zsh" "$(errors)"
pass "Manjikaze puts its zsh file in the custom directory of oh-my-zsh"

echo 'wta() { :; }' > "$CUSTOM/manjikaze.zsh"
run "$MANJIKAZE/bin/manjikaze" migrate --pending
cmp -s "$ROOT/configs/zsh/manjikaze.zsh" "$CUSTOM/manjikaze.zsh" || fail "Manjikaze replaces an outdated copy" "$(errors)"
pass "Manjikaze replaces an outdated copy of its zsh file"
