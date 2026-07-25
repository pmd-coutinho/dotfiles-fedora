// Idle management (replaces swayidle's timeouts): 10 min → lock,
// 15 min → monitors off. Respects the Wayland idle-inhibit protocol
// (video players etc.). NOTE: lock-before-sleep stays with a minimal
// swayidle -w in the niri autostart — quickshell has no logind sleep
// inhibitor yet, and locking before suspend must not race.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services

Scope {
    // Both monitors are switched off by the caffeine toggle (bar 󰅶). swayidle's
    // lock-before-sleep is untouched by it — suspend should always lock.
    IdleMonitor {
        timeout: 600
        respectInhibitors: true
        enabled: !Caffeine.active
        onIsIdleChanged: {
            // Session.lock() is idempotent (it just sets a bool), so the
            // pgrep guard the hyprlock era needed is gone.
            if (isIdle)
                Session.lock();
        }
    }

    IdleMonitor {
        timeout: 900
        respectInhibitors: true
        enabled: !Caffeine.active
        onIsIdleChanged: {
            if (isIdle)
                Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
        }
    }
}
