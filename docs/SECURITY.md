# Security notes

This repo is **public**. Audit summary and the security-relevant design choices.

## Audit (last reviewed 2026-06-18)

- **No secrets tracked**, and the full git history is clean — no private keys,
  cloud/API tokens, `age` keys, `.kdbx`, or inline passwords.
- Secret-bearing configs live **outside** the repo and are never stowed:
  `~/.config/rclone/rclone.conf` (Drive OAuth), SSH keys, the `~/vault/*.kdbx`.
  The helper scripts only reference *paths*.
- `.gitignore` has defensive rules (keys/`.kdbx`/`rclone.conf`/`.ssh`/…) so an
  accidental `git add -A` can't pull a credential in.
- `git/.gitconfig` carries the personal Gmail as commit identity — intentional,
  but note it's publicly harvestable (true of git authorship generally).
- `bootstrap.sh` installs `mise` via `curl https://mise.run | sh` (unpinned
  remote code). Accepted for a personal bootstrap; pin+verify if that changes.

## KeePassXC lookup (`bin/.local/bin/kp-walker`)

- Master password is read via `walker --password` and fed to `keepassxc-cli`
  over **stdin** (never argv).
- **Type** actions pipe the secret to `wtype` via **stdin** (`wtype -`), not as
  an argument — so it never appears in `/proc/<pid>/cmdline`.
- **Copy** actions use `wl-copy --sensitive` (sets the password-manager hint so
  compliant clipboard-history managers skip storing it) and auto-clear the live
  clipboard after 45s. **Verified (2026-06-18)**: elephant-clipboard (the walker
  `Mod+Shift+S` history) honors the hint — a `--sensitive` copy does not land in
  history, while normal copies do. So passwords copied via kp-walker stay out of
  clipboard history.

## Vault sync (`rclone-vault-sync.service`)

Bidirectional `rclone bisync ~/vault <-> gdrive:vault`, triggered on
`Passwords.kdbx` change and every 5 min. `--force` is needed (single-file dir
trips the >50%-changed guard), so the safety comes from:

- **`--backup-dir1 ~/vault-backup` / `--backup-dir2 gdrive:vault-backup`** — the
  previous version of any deleted/overwritten file is moved here first, so a bad
  sync is always recoverable. (Keeps the last-known-good; Drive's own version
  history covers deeper rollback.)
- **`--conflict-resolve newer --conflict-loser num`** — edits on two machines
  keep the newer as winner and preserve the older as `…​.kdbx.conflict1`; never a
  silent loss.
- **`--recover` / `--resilient`** — auto-recover from interrupted runs.
- **`--check-access`** (enabled) — `RCLONE_TEST` sentinel files live on both
  sides; if a side reads empty (unmounted/auth-expired remote), bisync aborts
  rather than propagating "delete everything".

After changing the flags: `systemctl --user daemon-reload` (no `--resync`
needed for backup-dir/conflict flags). Backup dirs are auto-created on first use.

If the `RCLONE_TEST` sentinels are ever lost, re-establish them:

```bash
touch ~/vault/RCLONE_TEST
rclone copyto ~/vault/RCLONE_TEST gdrive:vault/RCLONE_TEST
rclone bisync ~/vault gdrive:vault --check-access --resync --resync-mode path1 \
  --backup-dir1 ~/vault-backup --backup-dir2 gdrive:vault-backup
```
