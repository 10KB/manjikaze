# Firefox

Firefox is installed at `/usr/lib/firefox/firefox`. The path is stable across updates.

As a web browser, Firefox needs unrestricted network access. The only restriction
is blocking telemetry sent by a separate background process.

## Rules

### 000 – Deny telemetry (priority)

Firefox ships with a separate `pingsender` binary (`/usr/lib/firefox/pingsender`)
that sends usage statistics and crash reports to `incoming.telemetry.mozilla.org`
in the background, even after Firefox is closed.

This rule blocks that specific binary with `precedence: true`.

> **Tip:** Also disable telemetry in Firefox itself:
> *Settings → Privacy & Security → Firefox Data Collection and Use → Uncheck all*

### 001 – Allow all

Allow all connections from the main Firefox binary. A browser needs to reach
any destination by definition.
