# DBeaver

DBeaver uses the **system JRE** (`/usr/lib/jvm/java-*-openjdk/bin/java`),
not a bundled one. This means rules on this process path apply to all Java
apps using the system JRE — so we keep them restrictive.

## Rules

### 000 – Allow updates

Allow `dbeaver.io` for update checks and plugin marketplace downloads.
Uses a version-independent JRE path regex to survive Java upgrades.

## Database connections

Database connections are **not** covered by permanent rules. They vary per
project and per client, so it's better to approve them via the OpenSnitch
popup on a per-connection basis. Use "Allow for 12h" or "Allow for session"
for the duration of your work.
