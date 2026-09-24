# Repository instructions

Manjikaze provisions a Manjaro Linux development environment. The instructions below apply throughout this repository.

## Shell scripts

- Scripts manage Manjaro Linux. The configured interactive shell is zsh; use Bash for project scripts.
- Use Gum for interactive prompts: `gum choose` or `gum confirm` for choices, `gum input` for single-line text, and `gum write` for multi-line text.
- Make scripts safe to rerun. Handle errors explicitly and start scripts with `set -e`.
- Keep comments sparse; explain behavior only when it is not clear from the code.
- Use `pacman` for official repository packages and `yay` for AUR packages. For package transactions, include `--noconfirm --noprogressbar --quiet` where supported.
- Pass `-s` to `curl` commands for silent output.
- Use the existing `status` function for progress messages when it is available; keep logging consistent with the surrounding scripts.

## Documentation

- Documentation lives in `docs/` and uses VitePress. Use the existing scripts in `docs/package.json` when working on the documentation site.
