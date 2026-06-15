#!/usr/bin/env bash
# Round 3 root setup: GUI apps + CLI tools.
# Run as: sudo bash ~/dotfiles/setup-round3.sh   (sudo needed for repos/dnf)
# Flatpak + podman socket steps are user-level — see the USER section run as
# the invoking user. Idempotent.
set -uo pipefail
step() { echo -e "\n\033[1;35m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m!!  $*\033[0m"; }
ok()   { echo -e "\033[1;32m$*\033[0m"; }
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
RUSER="${SUDO_USER:-$(logname 2>/dev/null)}"
asuser() { sudo -u "$RUSER" env XDG_RUNTIME_DIR="/run/user/$(id -u "$RUSER")" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$RUSER")/bus" "$@"; }

# ── Third-party dnf repos ─────────────────────────────────────────────
step "VS Code (Microsoft repo)"
rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

step "Vivaldi (official repo)"
cat > /etc/yum.repos.d/vivaldi.repo <<'EOF'
[vivaldi]
name=vivaldi
baseurl=https://repo.vivaldi.com/archive/rpm/$basearch
enabled=1
gpgcheck=1
gpgkey=https://repo.vivaldi.com/archive/linux_signing_key.pub
EOF

step "OpenVPN3 + CLI tool COPRs"
# OpenVPN3 Linux via the maintainer's COPR. The STABLE dsommers/openvpn3 has
# no Fedora 44 build yet (only 41-43); the maintainer's dev-snapshot channel
# DOES build for F44, so use it. (packages.openvpn.net bare URLs 404.)
dnf -y copr disable dsommers/openvpn3 2>/dev/null || true   # stale: no F44 build
dnf -y copr enable dsommers/openvpn3-devsnapshots
dnf -y copr enable atim/lazygit
dnf -y copr enable atim/lazydocker

# ── Install ───────────────────────────────────────────────────────────
step "Installing GUI apps + CLI tools"
dnf -y install code vivaldi-stable bat ripgrep eza btop lazygit lazydocker solaar
dnf -y install openvpn3 || warn "openvpn3 install failed — check the OpenVPN repo URL/state"

# Slack: NATIVE rpm (not Flatpak). The Flatpak sandbox breaks notification
# action routing (clicking a notification never navigates to the conversation).
# Slack ships one universal el8 rpm that installs fine on Fedora and self-updates
# in-app, so the pinned version just needs to be installable; bump if it 404s.
SLACK_RPM="https://downloads.slack-edge.com/desktop-releases/linux/x64/4.50.136/slack-4.50.136-0.1.el8.x86_64.rpm"
dnf -y install "$SLACK_RPM" || warn "Slack rpm install failed — check $SLACK_RPM"

# ── USER-level: Flatpak + podman socket ───────────────────────────────
step "Unfiltering Flathub + installing flatpak apps (as $RUSER)"
flatpak remote-modify --no-filter flathub 2>/dev/null || true
# Install each separately so one failure doesn't abort the rest.
# Slack is installed natively above (rpm); drop any old Flatpak copy.
asuser flatpak uninstall -y com.slack.Slack 2>/dev/null || true
asuser flatpak install -y --noninteractive flathub md.obsidian.Obsidian || warn "Obsidian flatpak failed"
# AyuGram is NOT on Flathub — install the prebuilt bundle from 0FL01's repo.
step "AyuGram (prebuilt .flatpak from 0FL01/AyuGramDesktop-flatpak)"
AYU_URL=$(curl -fsSL "https://api.github.com/repos/0FL01/AyuGramDesktop-flatpak/releases/latest" \
  | python3 -c "import json,sys;[print(a['browser_download_url']) for a in json.load(sys.stdin)['assets'] if a['name'].endswith('.flatpak')]" | head -1)
if [ -n "$AYU_URL" ]; then
    curl -fsSL "$AYU_URL" -o /tmp/ayugram.flatpak
    asuser flatpak install -y --noninteractive /tmp/ayugram.flatpak || warn "AyuGram install failed"
else
    warn "couldn't resolve AyuGram .flatpak URL"
fi

step "Enabling podman socket for lazydocker (as $RUSER)"
asuser systemctl --user enable --now podman.socket 2>/dev/null || warn "enable podman.socket manually"

step "Microsoft Dev Tunnels CLI (devtunnel → ~/.local/bin)"
# Official installer dumps to ~/bin + edits .zshrc + apt-get; we just grab
# the binary into ~/.local/bin (already on PATH). Run 'devtunnel user login' after.
RHOME=$(getent passwd "$RUSER" | cut -d: -f6)
asuser curl -fsSL -o "$RHOME/.local/bin/devtunnel" \
  "https://tunnelsassetsprod.blob.core.windows.net/cli/linux-x64-devtunnel" \
  && chmod +x "$RHOME/.local/bin/devtunnel" && echo "  devtunnel installed" \
  || warn "devtunnel download failed"

echo
ok "Round 3 root setup done."
echo "Next (run as your user, not root):"
echo "  • JetBrains Toolbox: bash ~/dotfiles/install-toolbox.sh  (then open it, install Rider)"
echo "  • .NET via mise:     mise use -g dotnet@latest"
