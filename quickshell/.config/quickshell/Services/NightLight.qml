pragma Singleton
// Night light — quickshell OWNS wlsunset as a child process, so "on" is exact
// state, not a pgrep poll like the old waybar module. Manual switch, no
// schedule: -T 4001 next to -t 4000 keeps it warm whenever it runs.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool on: false

    function toggle() {
        on = !on;
    }

    Process {
        command: ["wlsunset", "-T", "4001", "-t", "4000"]
        running: root.on
    }

    // adopt a stray wlsunset from a previous session (waybar era / shell
    // restart): kill it and re-own the "on" state ourselves
    Process {
        id: adopt
        command: ["pkill", "-x", "wlsunset"]
        running: true
        onExited: exitCode => {
            if (exitCode === 0)
                root.on = true;
        }
    }
}
