#!/usr/bin/env bash
# ============================================================================
# Round 8 — dev/ops TUIs + helpers.
#   dnf:      gum (script UI), lnav (log navigator)
#   binaries: hurl (HTTP test files), mergiraf (structural merge driver),
#             trippy (`trip`, network diagnosis), kondo (build-artifact
#             cleaner), ouch (universal [de]compression), pay-respects
#             (command typo fixer — zshrc inits it)
#   uv tools: posting (API client TUI), isd (systemd unit TUI)
#   dotnet:   csharprepl (C# REPL, via the mise dotnet shim)
# Run as: sudo bash ~/dotfiles/setup-round8.sh   Idempotent.
# ============================================================================
set -uo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ── Packages (Fedora repos) ───────────────────────────────────────────────
step "Installing dnf packages (gum, lnav)"
dnf -y install gum lnav \
  || warn "one or more dnf packages failed — check names/repos"

# ── Prebuilt release binaries → ~/.local/bin ──────────────────────────────
# fetch_bin (lib/common.sh) is version-pinned + sha256-verified, fail-closed.
step "Fetching prebuilt binaries (hurl, mergiraf, trip, kondo, ouch, pay-respects)"
asuser mkdir -p "$UHOME/.local/bin"
fetch_bin hurl \
  "https://github.com/Orange-OpenSource/hurl/releases/download/8.0.1/hurl-8.0.1-x86_64-unknown-linux-gnu.tar.gz" \
  "cac7c4670d69444db120edb21fe06c97ba8c80dcc52279957c8dd18f05fb0c06"
fetch_bin mergiraf \
  "https://codeberg.org/mergiraf/mergiraf/releases/download/v0.17.0/mergiraf_x86_64-unknown-linux-gnu.tar.gz" \
  "8affcef50b86ce7ed450147f894ba3688bf3925bcbc2a9b3af2074d27e79e7c9"
# trippy's binary is named `trip`
fetch_bin trip \
  "https://github.com/fujiapple852/trippy/releases/download/0.13.0/trippy-0.13.0-x86_64-unknown-linux-musl.tar.gz" \
  "aa2b7b2a0773f3cc04da691100419049950b690fe3736d25e24ac955b63d6056"
fetch_bin kondo \
  "https://github.com/tbillington/kondo/releases/download/v0.9/kondo-x86_64-unknown-linux-musl.tar.gz" \
  "b8855f3ba710661d9d2fb37a32919531697e020b2c0973dc46b1ac52a38048bc"
fetch_bin ouch \
  "https://github.com/ouch-org/ouch/releases/download/0.8.1/ouch-x86_64-unknown-linux-musl.tar.gz" \
  "866884b08ea69fbab80bd79162df408519068a8fa232c2055038a1e561ad8f4c"
fetch_bin pay-respects \
  "https://github.com/iffse/pay-respects/releases/download/v0.8.8/pay-respects-0.8.8-x86_64-unknown-linux-musl.tar.zst" \
  "20bb89e9fa114b20ce78b57ece77134e79e314fd0d5086e9695c0de7f98ccaaf"

# ── uv tools (user-level, isolated venvs → ~/.local/bin) ──────────────────
step "uv tools: posting (API client), isd (systemd TUI)"
asuser uv tool install --quiet posting || warn "posting install failed"
asuser uv tool install --quiet isd-tui || warn "isd install failed"

# ── csharprepl (dotnet global tool, via the mise dotnet shim) ─────────────
step "csharprepl (C# REPL)"
DOTNET="$UHOME/.local/share/mise/shims/dotnet"
if asuser test -x "$DOTNET"; then
    asuser "$DOTNET" tool install -g csharprepl >/dev/null 2>&1 \
      || asuser "$DOTNET" tool update -g csharprepl >/dev/null 2>&1 \
      || warn "csharprepl install failed (is a dotnet SDK installed via mise?)"
else
    warn "mise dotnet shim not found — run 'mise use -g dotnet@9' then re-run"
fi

# mergiraf as a git merge driver is wired in git/.gitconfig +
# git/.config/git/attributes (stowed); nothing to configure here.

echo
ok "Round 8 done."
echo "  Try:  hurl --test api.hurl   |  lnav /var/log  |  trip 1.1.1.1"
echo "        kondo ~/dev            |  ouch d f.tar.zst  |  posting  |  isd"
echo "        csharprepl             |  gum choose a b c  |  typo a cmd, then 'f'"
