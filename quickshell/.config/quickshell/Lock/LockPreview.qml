pragma ComponentBehavior: Bound
// Preview harness for the lock screen: the same LockController + LockSurface
// in plain overlay windows instead of ext-session-lock, so the design can be
// screenshotted and the wrong-password path exercised without locking the
// session. NOT instantiated by shell.qml — run it from a copy of the config:
//
//   cp -r ~/.config/quickshell /tmp/qs-lock-test
//   # shell.qml of the copy: ShellRoot { LockPreview { id: p } IpcHandler {
//   #   target: "lock"; function lock(): void { Session.lock() }
//   #   function unlock(): void { Session.locked = false }
//   #   function wrong(): void { p.controller.tryUnlock("nope") } } }
//   qs -p /tmp/qs-lock-test &
//   qs ipc -p /tmp/qs-lock-test call lock lock
//
// Esc unlocks the preview (the real lock has no such key, obviously).
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services
import qs.Theme

Scope {
    readonly property alias controller: ctl

    LockController {
        id: ctl
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            visible: ctl.held
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-lock-preview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: Theme.crust

            LockSurface {
                anchors.fill: parent
                focus: true
                lock: ctl
                screen: win.modelData
                Keys.onEscapePressed: Session.locked = false
            }
        }
    }
}
