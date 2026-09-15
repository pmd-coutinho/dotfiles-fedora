pragma Singleton
// Who is logged in, for the lock screen and the control center header: the
// account name, the GECOS full name, an avatar if ~/.face exists, the hostname
// and an on-demand uptime string.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string name: Quickshell.env("USER") ?? ""
    readonly property string home: Quickshell.env("HOME") ?? ""
    property string fullName: name
    // "file:///home/x/.face" or "" — the shell draws an initial when empty
    property string avatarUrl: ""
    readonly property string initial: (fullName || name || "?").charAt(0).toUpperCase()
    readonly property string hostname: hostFile.text().trim()

    // One probe at startup: GECOS name (first comma field) and the avatar file.
    Process {
        running: true
        command: ["sh", "-c",
            "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1; " +
            "for f in \"$HOME/.face\" \"$HOME/.face.icon\"; do [ -f \"$f\" ] && { echo \"$f\"; break; }; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const gecos = (lines[0] ?? "").trim();
                if (gecos !== "")
                    root.fullName = gecos;
                const face = (lines[1] ?? "").trim();
                root.avatarUrl = face !== "" ? "file://" + face : "";
            }
        }
    }

    FileView {
        id: hostFile
        path: "/etc/hostname"
        printErrors: false
    }

    // ── uptime ──
    // /proc/uptime is re-read only when a consumer asks (the control center
    // header runs a 60s timer while it is open) — nothing ticks in the
    // background.
    property real uptimeSecs: 0
    readonly property string uptimeText: {
        const s = uptimeSecs;
        if (s <= 0)
            return "";
        const d = Math.floor(s / 86400);
        const h = Math.floor((s % 86400) / 3600);
        const m = Math.floor((s % 3600) / 60);
        if (d > 0)
            return "up " + d + "d " + h + "h";
        if (h > 0)
            return "up " + h + "h " + m + "m";
        return "up " + m + "m";
    }

    function refreshUptime() {
        uptimeFile.reload();
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        printErrors: false
        onLoaded: root.uptimeSecs = Number(text().split(" ")[0]) || 0
    }
}
