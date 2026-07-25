pragma Singleton
// Screen-recording state, pushed in by bin/screen-record over IPC.
//
// Not polled: the script owns the encoder process and its pidfile, so it is the
// only thing that reliably knows whether a recording is live. `active` survives
// config reloads so the indicator doesn't vanish mid-recording when the shell
// hot-reloads, and it is re-checked against the pidfile at startup so a
// quickshell restart during a recording doesn't lose the indicator.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias active: persist.active

    PersistentProperties {
        id: persist
        reloadableId: "recorder"

        property bool active: false
    }

    function stop() {
        // the script is a toggle: running it again stops the recording and
        // sends us `stopped`
        Quickshell.execDetached(["screen-record"]);
    }

    // A fresh quickshell process has no idea whether a recording is in flight,
    // so ask the pidfile once at startup.
    Process {
        running: true
        command: ["sh", "-c",
            "f=\"${XDG_RUNTIME_DIR:-/tmp}/screen-record.pid\"; " +
            "[ -s \"$f\" ] && kill -0 \"$(head -1 \"$f\")\" 2>/dev/null && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: persist.active = text.trim() === "yes"
        }
    }
}
