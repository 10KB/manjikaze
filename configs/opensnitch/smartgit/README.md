# SmartGit

SmartGit runs via a bundled JRE at `/opt/smartgit/jre/bin/java`.

Because it uses a bundled JRE, SmartGit does its own DNS resolution rather
than using the system resolver. This requires a separate DNS allow rule.

## Rules

### 000 – Allow SmartGit domains

| Domain pattern | Purpose |
|---|---|
| `*.syntevo.com` | License verification (`license.`), API (`api.`) |
| `*.smartgit.dev` | Update checks, release notes |
| `*.gravatar.com` | Commit author profile avatars |
| `*.github.com` | GitHub repository access, API |
| `*.gitlab.com` | GitLab repository access, API |

### 001 – Allow DNS

Allow SmartGit's JRE to perform DNS queries on port 53. Matched on port
rather than specific DNS server IPs since DNS configuration may vary.
