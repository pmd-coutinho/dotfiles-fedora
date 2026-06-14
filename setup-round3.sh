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

step "OpenVPN3 (OpenVPN official repo)"
# OpenVPN's Fedora repo for the openvpn3 client.
rpm --import https://packages.openvpn.net/packages-repo.gpg 2>/dev/null || \
  rpm --import https://swupdate.openvpn.net/repos/repo-public.gpg 2>/dev/null || \
  warn "couldn't import OpenVPN key — verify URL at packages.openvpn.net"
if command -v dnf4 >/dev/null || dnf --version 2>/dev/null | grep -q '^4'; then
    dnf config-manager --add-repo https://packages.openvpn.net/openvpn3/fedora/openvpn3-fedora.repo 2>/dev/null || true
else
    dnf config-manager addrepo --from-repofile=https://packages.openvpn.net/openvpn3/fedora/openvpn3-fedora.repo 2>/dev/null || true
fi

step "CLI tool COPRs (lazygit, lazydocker)"
dnf -y copr enable atim/lazygit
dnf -y copr enable atim/lazydocker

# ── Install ───────────────────────────────────────────────────────────
step "Installing GUI apps + CLI tools"
dnf -y install code vivaldi-stable bat ripgrep eza btop lazygit lazydocker
dnf -y install openvpn3 || warn "openvpn3 install failed — check the OpenVPN repo URL/state"

# ── USER-level: Flatpak + podman socket ───────────────────────────────
step "Unfiltering Flathub + installing flatpak apps (as $RUSER)"
asuser flatpak remote-modify --user --no-filter flathub 2>/dev/null \
  || flatpak remote-modify --no-filter flathub 2>/dev/null || true
AYU=$(asuser flatpak search ayugram 2>/dev/null | awk '{print $NF}' | grep -i ayugram | head -1)
AYU=${AYU:-com.ayugram.desktop}
echo "  AyuGram app id: $AYU"
asuser flatpak install -y --noninteractive flathub com.slack.Slack md.obsidian.Obsidian "$AYU" \
  || warn "one or more flatpaks failed — check 'flatpak search'"

step "Enabling podman socket for lazydocker (as $RUSER)"
asuser systemctl --user enable --now podman.socket 2>/dev/null || warn "enable podman.socket manually"

echo
ok "Round 3 root setup done."
echo "Next (run as your user, not root):"
echo "  • JetBrains Toolbox: bash ~/dotfiles/install-toolbox.sh  (then open it, install Rider)"
echo "  • .NET via mise:     mise use -g dotnet@latest"
