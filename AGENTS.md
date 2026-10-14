# AGENTS.md

## What this is

`fluxr` — a multi-host backup orchestrator. A single bash script wrapped as a
Nix package.

## Layout

```
flake.nix          — Nix flake entry; outputs x86_64-linux packages
package.nix        — Nix derivation: installs src/fluxr.sh, wraps PATH
src/fluxr.sh       — the entire application
```

## Build

```bash
nix build
```

No tests. No complex build — `package.nix` copies `src/fluxr.sh` to `$out/bin/fluxr` and wraps PATH to include rclone, rsync, openssh, coreutils.

## What's outside the repo

Configuration is **not** version-controlled. It lives on each host at:

- `$HOME/.config/fluxr/<hostname>.sh` — per-host backup config
- `$HOME/.config/fluxr/remotes/<remote>.sh` — per-rclone-remote sync targets
- `$HOME/.local/share/fluxr/` — runtime state (generated include files, command scripts)

## Dependencies

| Dependency | Used for |
| --- | --- |
| rclone | Default sync command (`rclone sync`) |
| rsync | SSH transport to remote hosts |
| openssh | SSH to remote hosts |
| coreutils | Basic POSIX commands |

## Code style

- Bash script, uses bashisms (`[[`, `${array[@]}`, etc.)
- `shellcheck` annotations present (`# shellcheck source=/dev/null`)
- Pre-commit hooks via symlinked `.pre-commit-config.yaml`

## What the script does

1. Reads per-host configs from `$HOME/.config/fluxr/*.sh`
2. For each host: runs `rclone sync` (or a custom `$COMMAND`) to back up `$ROOT` to `$TARGET`
3. For remote hosts: syncs config over SSH, then runs the backup via `nix run` on the remote
4. After local/remote backups: runs `rclone_sync` for inter-remote transfers defined in `$HOME/.config/fluxr/remotes/`
