// Idle management (replaces swayidle's timeouts): 10 min → lock,
// 15 min → monitors off. Respects the Wayland idle-inhibit protocol
// (video players etc.). NOTE: lock-before-sleep stays with a minimal
// swayidle -w in the niri autostart — quickshell has no logind sleep
// inhibitor yet, and locking before suspend must not race.
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    IdleMonitor {
        timeout: 600
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                Quickshell.execDetached(["sh", "-c", "pgrep -x hyprlock || hyprlock"]);
        }
    }

    IdleMonitor {
        timeout: 900
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
        }
    }
}
