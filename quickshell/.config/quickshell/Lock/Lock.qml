pragma ComponentBehavior: Bound
// Session lock (ext-session-lock + PAM).
//
// This is the active locker (idle, before-sleep and Super+Alt+L all route
// here via Services/Session.qml). Escape hatch if the shell ever dies while
// locked: niri keeps the session locked, so switch to a TTY (Ctrl+Alt+F3) and
// restart quickshell from there — `niri msg action do-screen-transition`
// won't help. Watch for quickshell-mirror#503 (monitor power-off while locked).
//
// The state machine (PAM, backoff, fade) is LockController.qml and the per-
// output view is LockSurface.qml, so LockPreview.qml can show the exact same
// screen in an ordinary window for screenshots and wrong-password testing
// without locking anything.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Theme

Scope {
    LockController {
        id: ctl
    }

    WlSessionLock {
        locked: ctl.held

        WlSessionLockSurface {
            id: surface

            color: Theme.crust

            LockSurface {
                anchors.fill: parent
                lock: ctl
                screen: surface.screen
            }
        }
    }
}
