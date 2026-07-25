pragma Singleton
// Session actions — the single place the shell locks, logs out or powers down.
// Before this existed the lock was invoked from three places in three different
// ways (an `execDetached(["hyprlock"])` here, a `pgrep -x hyprlock || hyprlock`
// there); now Idle, the notification panel, the session menu and the `lock`
// IpcHandler all call Session.lock() and Lock/Lock.qml binds to `locked`.
import QtQuick
import Quickshell

Singleton {
    id: root

    // Lock/Lock.qml binds WlSessionLock.locked to this. Writable because the
    // PAM success path in Lock.qml clears it — it is the one legitimate writer
    // besides lock() below.
    property bool locked: false

    function lock() {
        locked = true;
    }

    function logout() {
        Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]);
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
