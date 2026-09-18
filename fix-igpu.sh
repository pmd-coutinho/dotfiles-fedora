#!/usr/bin/env bash
# Intel iGPU boot arguments, chosen by the MSI GPU MUX mode (see README "GPU MUX").
#
#   Discrete mode (current since 2026-09-17): the panel and every external port
#   hang off the RTX 4080 and the iGPU has no outputs. It must NOT get a DRM
#   driver: plymouth hands the splash from simpledrm to the first real DRM card
#   that appears, and an output-less i915 turns the LUKS passphrase prompt into
#   a black screen (typing blind doesn't help — the prompt is torn down).
#   → keep i915 + xe OUT of the initramfs image (dracut omit_drivers) and drop
#     force_probe. i915 must still load after switch-root: the Intel HD Audio
#     controller (SOF) carries an HDMI codec that binds to the i915 audio
#     component, and without i915 its probe defers forever ("init of i915 and
#     HDMI codec failed") — no speakers, mic or jack. NOTE: rd.driver.blacklist
#     is NOT initramfs-only — dracut writes it to /run/modprobe.d/, which
#     survives switch-root, so it would blacklist i915 for the whole boot.
#
#   MSHybrid mode: kernel 7.0 moved Raptor Lake-S graphics (8086:a788) from i915
#   to xe, but xe only binds it behind force_probe; without it the laptop panel +
#   Huawei (wired to the iGPU in that mode) have no driver at all.
#   → xe.force_probe=a788, no i915/xe blacklist.
#
# The mode is read from the MsiDCVarData UEFI variable (byte 5 bits 2-3).
# Run as: sudo bash ~/dotfiles/fix-igpu.sh   — then reboot.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

BASE_BL="nouveau,nova_core"
FORCE="xe.force_probe=a788"
DRACUT_CONF=/etc/dracut.conf.d/igpu-discrete.conf
VAR=/sys/firmware/efi/efivars/MsiDCVarData-dd96baaf-145e-4f56-b1cf-193256298e99

mode=hybrid
if [ -r "$VAR" ]; then
    # efivarfs prepends 4 attribute bytes; byte 5 of the payload is offset 9.
    b5=$(od -An -tu1 -j9 -N1 "$VAR" | tr -d ' ')
    case $(( (b5 >> 2) & 3 )) in
        1) mode=discrete ;;
        2) mode=integrated ;;
    esac
fi
echo "==> MUX mode: $mode"

if [ "$mode" = discrete ]; then
    REMOVE="xe.force_probe rd.driver.blacklist modprobe.blacklist"
    ADD="rd.driver.blacklist=$BASE_BL modprobe.blacklist=$BASE_BL,xe"
    echo "==> Omitting i915/xe from the initramfs ($DRACUT_CONF)"
    cat > "$DRACUT_CONF" <<'EOF'
# Discrete GPU MUX mode: the Intel iGPU has no outputs. Keep its DRM drivers out
# of the initramfs so plymouth never hands the LUKS prompt to an output-less
# card. They still load from the real root (SOF audio needs i915).
omit_drivers+=" i915 xe "
EOF
else
    REMOVE="rd.driver.blacklist modprobe.blacklist"
    ADD="rd.driver.blacklist=$BASE_BL modprobe.blacklist=$BASE_BL $FORCE"
    if [ -f "$DRACUT_CONF" ]; then
        echo "==> Removing $DRACUT_CONF (iGPU drives outputs in this mode)"
        rm -f "$DRACUT_CONF"
    fi
fi

echo "==> Updating existing boot entries: -[$REMOVE] +[$ADD]"
grubby --update-kernel=ALL --remove-args="$REMOVE" --args="$ADD"

echo "==> Persisting for future kernels (/etc/default/grub)"
# Rewrite the three managed keys in GRUB_CMDLINE_LINUX, leave everything else.
python3 - "$ADD" <<'PY'
import re, sys, pathlib
add = sys.argv[1].split()
p = pathlib.Path('/etc/default/grub'); s = p.read_text()
m = re.search(r'^GRUB_CMDLINE_LINUX="([^"]*)"', s, re.M)
args = [a for a in m.group(1).split()
        if not a.startswith(('rd.driver.blacklist=', 'modprobe.blacklist=', 'xe.force_probe='))]
p.write_text(s[:m.start(1)] + ' '.join(args + add) + s[m.end(1):])
PY

echo "==> Rebuilding initramfs for the running kernel"
dracut -f || echo "!! dracut failed — the initramfs still has the old driver set"

echo "==> Result:"
grubby --info=DEFAULT | grep args
echo
echo "Done — reboot for the new arguments and initramfs to take effect."
