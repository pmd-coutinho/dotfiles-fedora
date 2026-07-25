#!/usr/bin/env bash
# ============================================================================
# Round 10 — the gaps left after the July 2026 audit.
#   dnf:      restic (off-machine backup — the one real hole in the story),
#             git-absorb (auto-fixup into the right commit), hexyl (hex viewer;
#             bat does not do binaries), tokei (LOC on NopCommerce-scale trees)
#   binaries: ast-grep (structural search/rewrite — the missing third leg next
#             to difftastic for structural diff and mergiraf for structural
#             merge, on a codebase that is mostly C#)
# Run as: sudo bash ~/dotfiles/setup-round10.sh   Idempotent.
#
# NOT installed here, deliberately:
#   sops — would let secrets live encrypted IN this public repo (age is already
#          installed and there is a kept age key), but that is a workflow change
#          to opt into, not a package to drop in. mise.local.toml is currently
#          protected by gitignore alone.
# ============================================================================
set -uo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── Packages (Fedora repos) ───────────────────────────────────────────────
step "Installing dnf packages (restic, git-absorb, hexyl, tokei)"
dnf -y install restic git-absorb hexyl tokei \
  || warn "one or more dnf packages failed — check names/repos"

# ── ast-grep (pinned release, sha256-verified) ────────────────────────────
# The archive ships two names for the same tool: `ast-grep` and the short `sg`.
# Only take `ast-grep` — `sg` collides with shadow-utils' /usr/bin/sg (setgid
# shell), and shadowing that from ~/.local/bin would be a genuinely bad idea.
step "ast-grep 0.45.0 (structural search/rewrite)"
if command -v ast-grep >/dev/null 2>&1; then
    ok "  ast-grep already installed"
else
    fetch_bin ast-grep \
      "https://github.com/ast-grep/ast-grep/releases/download/0.45.0/app-x86_64-unknown-linux-gnu.zip" \
      "78931ae35ebac33d9a72b3aecea3e3d62d6e5b0b718ac8bbedfbe69d68421e41"
fi

echo
ok "Round 10 done."
echo "  restic is installed but NOT configured — it needs a destination and a"
echo "  password before it backs anything up. Nothing in ~ or ~/dev is currently"
echo "  backed up off-machine (snapper is root-only; rclone bisync covers only"
echo "  the KeePassXC vault). See docs/SECURITY.md for the vault-sync pattern."
echo "  ast-grep: invoke as 'ast-grep', not 'sg' (see the note above)."
