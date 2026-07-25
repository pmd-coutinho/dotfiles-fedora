pragma Singleton
// Night light — quickshell OWNS wlsunset as a child process, so "on" is exact
// state, not a pgrep poll like the old waybar module. Manual switch, no
// schedule: -T 4001 next to -t 4000 keeps it warm whenever it runs.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias on: persist.on

    function toggle() {
        on = !on;
    }

    // `on` and `adopted` survive config reloads — see the adoption note below.
    PersistentProperties {
        id: persist
        reloadableId: "nightlight"

        property bool on: false
        property bool adopted: false
    }

    Process {
        command: ["wlsunset", "-T", "4001", "-t", "4000"]
        running: root.on
    }

    // Adopt a stray wlsunset from a previous session (waybar era / shell
    // restart): kill it and re-own the "on" state ourselves.
    //
    // This used to be `running: true`, which re-ran on EVERY hot reload — so
    // editing any unrelated file killed the shell's own wlsunset, inferred
    // "night light was on" from pkill's exit code, and restarted it. Night
    // light state flipped on unrelated edits. `adopted` persists across
    // reloads so the adoption happens once per process instead.
    Process {
        command: ["pkill", "-x", "wlsunset"]
        running: !persist.adopted
        onExited: exitCode => {
            persist.adopted = true;
            if (exitCode === 0)
                persist.on = true;
        }
    }
}
