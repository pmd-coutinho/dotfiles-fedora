pragma Singleton
// "Caffeine" — suppress the shell's own idle timeouts (lock at 10m, screens off
// at 15m) for presentations, long builds, or watching something in a player that
// doesn't take an idle inhibitor of its own.
//
// Implemented by disabling our IdleMonitors rather than taking a Wayland
// idle-inhibit lock: the protocol's inhibitor is per-SURFACE (IdleInhibitor
// wants a `window`), which is awkward from a singleton, and the thing we
// actually want to stop is our own Idle.qml. Note this does NOT inhibit
// swayidle's lock-before-sleep — suspending should still lock, always.
//
// Persisted across config reloads so an edit mid-presentation doesn't
// re-arm the lock behind your back.
import QtQuick
import Quickshell

Singleton {
    id: root

    property alias active: persist.active

    function toggle() {
        active = !active;
    }

    PersistentProperties {
        id: persist
        reloadableId: "caffeine"

        property bool active: false
    }
}
