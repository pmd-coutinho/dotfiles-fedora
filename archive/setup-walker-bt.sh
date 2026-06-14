#!/usr/bin/env bash
# Install walker + elephant (launcher) and bring up bluetooth.
# Run as: sudo bash ~/dotfiles/setup-walker-bt.sh
set -uo pipefail
step() { echo -e "\n\033[1;35m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m!!  $*\033[0m"; }
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

# ── Walker (Wayland launcher) + Elephant backend ─────────────────────
step "Enabling walker COPR (errornointernet/walker)"
dnf -y copr enable errornointernet/walker

step "Installing walker + elephant"
dnf -y install walker elephant || { warn "walker/elephant install failed"; exit 1; }

# ── Bluetooth ────────────────────────────────────────────────────────
# NOTE: bluetooth lives in the kernel-modules package, which was missing
# from the half-installed 7.0.12 kernel. That fix is in
# fix-kernel-modules.sh — run that, not a bare `systemctl start` here
# (the controller doesn't exist until the modules are installed).
warn "Bluetooth is fixed by fix-kernel-modules.sh — see that script."

echo
echo -e "\033[1;32mWalker installed. Tell Claude — it'll enable the elephant user service, stow walker, and restart the bars.\033[0m"
