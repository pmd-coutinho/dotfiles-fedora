#!/usr/bin/env bash
# Round 4 — OS hardening: NVIDIA suspend, journald cap, inotify, snapshots.
# Run as: sudo bash ~/dotfiles/setup-round4.sh
set -uo pipefail
step() { echo -e "\n\033[1;35m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m!!  $*\033[0m"; }
ok()   { echo -e "\033[1;32m$*\033[0m"; }
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

# ── 1. NVIDIA: preserve VRAM across suspend/resume ───────────────────────
# The nvidia-suspend/resume/hibernate services are enabled but inert without
# this — without it, suspend can return a black/corrupted session.
step "Enabling NVreg_PreserveVideoMemoryAllocations"
cat > /etc/modprobe.d/nvidia-power.conf <<'EOF'
options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp
EOF
step "Rebuilding initramfs (nvidia options live in the ramdisk)"
dracut -f --regenerate-all || warn "dracut failed — check before relying on suspend"

# ── 2. journald size cap ─────────────────────────────────────────────────
step "Capping journald to 500M"
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/size.conf <<'EOF'
[Journal]
SystemMaxUse=500M
EOF
systemctl restart systemd-journald 2>/dev/null || true

# ── 3. inotify instances (dev file-watchers: Rider + VS Code + dotnet watch)
step "Raising fs.inotify.max_user_instances"
cat > /etc/sysctl.d/99-inotify.conf <<'EOF'
# Heavy dev: multiple IDEs + dotnet watch exhaust the default 128 instances.
fs.inotify.max_user_instances = 1024
fs.inotify.max_user_watches = 524288
EOF
sysctl --system >/dev/null 2>&1 || true

# ── 4. btrfs snapshots (snapper, root only, timeline) ────────────────────
# Root only (NOT /home) — a system rollback never touches your files/dotfiles.
step "Installing snapper + btrfs-assistant"
dnf -y install snapper btrfs-assistant || { warn "snapper install failed"; exit 1; }

if ! snapper list-configs 2>/dev/null | grep -qw root; then
    step "Creating snapper config for / (root subvol)"
    snapper -c root create-config / || warn "create-config failed (check subvol layout)"
fi
# Sensible retention.
if [ -f /etc/snapper/configs/root ]; then
    sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="6"/;
            s/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/;
            s/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="2"/;
            s/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/;
            s/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root
fi
step "Enabling snapshot timers"
systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

echo
ok "Round 4 done. REBOOT to load the NVIDIA suspend option."
echo "Snapshots: 'snapper list' to see them; 'btrfs-assistant' for a GUI."
echo "Recovery if a kernel/driver update breaks boot: pick the stock Fedora"
echo "kernel in GRUB, then 'sudo snapper rollback <N>' and reboot."
echo "Optional later: grub-btrfs (COPR) adds boot-to-snapshot entries in GRUB."
