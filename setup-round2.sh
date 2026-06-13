#!/usr/bin/env bash
# Round 2 root setup: packages, swap+zswap, power auto-switch, tuigreet
# polish, and the CachyOS kernel (+ nvidia akmod rebuild).
# Run as: sudo bash ~/dotfiles/setup-round2.sh
# Idempotent where practical; written to never hang.
set -uo pipefail
step() { echo -e "\n\033[1;35m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m!!  $*\033[0m"; }
ok()   { echo -e "\033[1;32m$*\033[0m"; }
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

ZSWAP_ARGS="zswap.enabled=1 zswap.compressor=zstd zswap.zpool=zsmalloc zswap.max_pool_percent=25"

# ── 1. Packages ───────────────────────────────────────────────────────
step "Enabling CachyOS kernel COPR"
dnf -y copr enable bieszczaders/kernel-cachyos || { warn "COPR enable failed"; exit 1; }

step "Installing satty, elephant-files, and the CachyOS kernel (GCC, not -lto)"
dnf -y install satty elephant-files kernel-cachyos kernel-cachyos-devel-matched \
    || { warn "package install failed"; exit 1; }
step "Removing useless elephant-archlinuxpkgs"
dnf -y remove elephant-archlinuxpkgs 2>/dev/null || true

# ── 2. Swap → disk swapfile + zswap (replace zram) ────────────────────
step "Disabling zram"
echo "# zram disabled in favour of disk swap + zswap (see setup-round2.sh)" > /etc/systemd/zram-generator.conf
swapoff /dev/zram0 2>/dev/null || true

step "Creating 32G btrfs swapfile on its own subvolume"
if ! swapon --show=NAME --noheadings | grep -q '/swap/swapfile'; then
    [ -d /swap ] || btrfs subvolume create /swap
    if [ ! -f /swap/swapfile ]; then
        btrfs filesystem mkswapfile --size 32g /swap/swapfile
    fi
    swapon /swap/swapfile
fi
grep -q '^/swap/swapfile' /etc/fstab || echo '/swap/swapfile none swap defaults 0 0' >> /etc/fstab

step "Enabling zswap on the kernel cmdline (all entries + future kernels)"
grubby --update-kernel=ALL --args="$ZSWAP_ARGS"
# persist for newly installed kernels (BLS reads /etc/kernel/cmdline)
if [ -f /etc/kernel/cmdline ]; then
    for a in $ZSWAP_ARGS; do grep -q -- "$a" /etc/kernel/cmdline || sed -i "s|\$| $a|" /etc/kernel/cmdline; done
fi
if grep -q '^GRUB_CMDLINE_LINUX=' /etc/default/grub; then
    for a in $ZSWAP_ARGS; do grep -q -- "$a" /etc/default/grub || sed -i "s|\(^GRUB_CMDLINE_LINUX=\"[^\"]*\)\"|\1 $a\"|" /etc/default/grub; done
fi

step "Swap sysctl tuning"
cat > /etc/sysctl.d/99-swap.conf <<'EOF'
# Lean on the fast zswap tier; reclaim caches less aggressively.
vm.swappiness = 100
vm.vfs_cache_pressure = 50
EOF
sysctl --system >/dev/null 2>&1 || true

# ── 3. Power — tuned-ppd auto AC/battery switch ───────────────────────
step "Enabling tuned"
systemctl enable --now tuned >/dev/null 2>&1 || true

step "Power-profile auto-switch udev rule (via net.hadess.PowerProfiles D-Bus)"
SET='/usr/bin/busctl --system set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile s'
cat > /etc/udev/rules.d/99-power-profile.rules <<EOF
# Plugged in -> performance (tuned throughput-performance); battery -> balanced
# (tuned-ppd auto-refines to balanced-battery). systemd-run detaches from udev.
SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/bin/systemd-run --no-block $SET performance"
SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="/usr/bin/systemd-run --no-block $SET balanced"
EOF
udevadm control --reload 2>/dev/null || true

# ── 4. tuigreet polish ────────────────────────────────────────────────
step "Polishing tuigreet / greetd"
cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --time-format '%a %d %b  %H:%M' --remember --remember-user-session --asterisks --greet-align center --sessions /usr/share/wayland-sessions --cmd niri-session --theme 'border=magenta;text=white;prompt=lightmagenta;time=blue;action=lightblue;button=lightmagenta;container=black;input=white' --greeting 'welcome back, pedro' --power-shutdown 'systemctl poweroff' --power-reboot 'systemctl reboot' --kb-power 12"
user = "greetd"
EOF

# ── 5. CachyOS kernel: build nvidia akmod + set default iff it works ──
CK="$(ls -d /usr/lib/modules/*cachyos* 2>/dev/null | xargs -n1 basename | sort -V | tail -1)"
if [ -z "$CK" ]; then
    warn "CachyOS kernel modules dir not found — skipping akmod/default. Check 'dnf list installed kernel-cachyos*'."
else
    step "Building nvidia akmod for $CK"
    NMODS=$(find "/usr/lib/modules/$CK/kernel" -name '*.ko*' 2>/dev/null | wc -l)
    echo "  module count for $CK: $NMODS"
    [ "$NMODS" -lt 2000 ] && warn "  low module count — kernel-cachyos may be missing its modules subpackage"
    akmods --kernels "$CK" --force >/tmp/akmods-cachyos.log 2>&1 || true
    step "Waiting for the nvidia module to finish building (capped ~10 min)"
    built=""
    for i in $(seq 1 60); do
        if modinfo -F version nvidia -k "$CK" >/dev/null 2>&1; then built=1; break; fi
        sleep 10; echo "  building... (${i}0s)"
    done
    if [ -n "$built" ]; then
        ok "nvidia built for $CK: $(modinfo -F version nvidia -k "$CK")"
        step "Setting $CK as the default boot kernel"
        grubby --set-default "/boot/vmlinuz-$CK"
        ok "Default kernel = $CK (stock Fedora kernel remains in the GRUB menu)"
    else
        warn "nvidia did NOT build for $CK (see /tmp/akmods-cachyos.log)."
        warn "Leaving the stock Fedora kernel as default. Do NOT boot CachyOS until this is fixed."
    fi
fi

echo
ok "Round 2 root setup done. Review, then reboot."
echo "Rescue: at GRUB pick the Fedora kernel; or TTY -> 'sudo grubby --set-default /boot/vmlinuz-\$(rpm -q --qf '%{version}-%{release}.%{arch}' kernel-core | grep -v cachyos)'"
