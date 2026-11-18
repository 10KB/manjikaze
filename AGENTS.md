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
- A new installation records every migration as done without running it. Make the same change in the install scripts as in the migration, so new installations get it too.

## Checks

- Run `checks/run.sh` before you commit; it needs `shellcheck`, `luac`, `python3` and `jq`. CI runs the same checks on every pull request, and builds the documentation.
- Run a single check with `checks/run.sh <check>`, for example `checks/run.sh shellcheck`.

## Tests

- Behaviour tests live in `tests/<area>-test.sh` and run with `tests/run.sh`, which `checks/run.sh tests` also runs. They source `tests/lib.sh` for a scratch `HOME`, stubs for `gum` and `sudo`, and `pass` and `fail`.
- A test must fail without the change it covers. Don't write tests that only repeat what the code says.
- Migrations get no tests of their own. Move logic that needs a test into `lib/` or `bin/` and test it there.

## Documentation

- Documentation lives in `docs/` and uses VitePress. Use the existing scripts in `docs/package.json` when working on the documentation site.
