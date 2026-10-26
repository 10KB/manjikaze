# System Package Installs

Besides the git install from `install.sh`, Manjikaze can run as a system package, for example when an organization distributes it through its own pacman repository. A package install runs the same code from a read-only directory.

## Layout

| Path | Content |
|------|---------|
| `/usr/share/manjikaze/` | `bin`, `lib`, `app`, `audits`, `configs`, `migrations` and `assets` |
| `/usr/share/manjikaze/VERSION` | Version shown in the header |
| `/usr/bin/manjikaze` | Symlink to `/usr/share/manjikaze/bin/manjikaze` |
| `~/.local/share/manjikaze/` | Per-user state file and `secrets/` |

Manjikaze treats a directory with a `VERSION` file and without `.git` as a package install. It then:

- skips its own update check, because the package manager updates Manjikaze;
- stores the state file and secrets in `$MANJIKAZE_DATA_DIR`, which defaults to `${XDG_DATA_HOME:-~/.local/share}/manjikaze`.

Git installs keep both in `~/.manjikaze`, as before.

## Building a Package

- Install `bin`, `lib`, `app`, `audits`, `configs`, `migrations` and `assets` into `/usr/share/manjikaze/`. Leave out `docs`, `install.sh`, `secrets` and development files.
- Write the version to `/usr/share/manjikaze/VERSION`.
- Link `/usr/bin/manjikaze` to `/usr/share/manjikaze/bin/manjikaze`.
- Remove `/usr/local/bin/manjikaze` if it is the wrapper from `install.sh`. It comes before `/usr/bin` on `PATH` and would start the git install.

## Switching from a Git Install

`manjikaze setup` prepares a package install for the current user. Manjikaze also runs it on every start, before it reads the state file:

- It copies `~/.manjikaze/.manjikaze_state.json` and `~/.manjikaze/secrets/` to the data directory, so finished migrations and audits don't run again.
- It removes the desktop entry that `install.sh` created.
- It points the weekly update check at the package.

`manjikaze setup` never deletes `~/.manjikaze`. Remove it yourself once the package install works, after checking that your secrets are in the data directory or in your password manager.
