pragma Singleton
// The laptop panel backlight: discovered once from /sys/class/backlight (the
// device name differs per driver — intel_backlight, amdgpu_bl0, nv_backlight —
// so it is never hardcoded), watched through sysfs for changes made by anyone
// (the niri brightness keys call brightnessctl directly), and writable from the
// control center slider through the same brightnessctl.
//
// `changedExternally` is what the OSD listens to: a change that this service
// itself just requested is not "news" to show the user a popup about, they are
// already dragging a slider.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string dir: ""
    readonly property bool available: dir !== ""
    // 0..1
    property real level: 0
    property int maxRaw: 1

    signal changedExternally(real level)

    // When our own write is echoed back by sysfs within this window, swallow it.
    property double lastSetAt: 0

    Process {
        running: true
        command: ["sh", "-c", "ls -d /sys/class/backlight/*/ 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const d = text.trim().replace(/\/$/, "");
                if (d !== "")
                    root.dir = d;
            }
        }
    }

    FileView {
        id: maxFile
        path: root.dir === "" ? "" : root.dir + "/max_brightness"
        printErrors: false
        onLoaded: {
            root.maxRaw = Math.max(1, Number(text().trim()) || 1);
            cur.reload();
        }
    }

    FileView {
        id: cur
        path: root.dir === "" ? "" : root.dir + "/brightness"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const v = Math.min(1, Math.max(0, (Number(text().trim()) || 0) / root.maxRaw));
            root.level = v;
            if (Date.now() - root.lastSetAt > 600)
                root.changedExternally(v);
        }
    }

    // Slider drags fire many times a second; coalesce into one brightnessctl
    // call per 50ms and reflect the target immediately so the knob doesn't lag.
    property real pending: -1

    function set(value) {
        const v = Math.min(1, Math.max(0, value));
        level = v;
        pending = v;
        lastSetAt = Date.now();
        if (!coalesce.running)
            coalesce.start();
    }

    Timer {
        id: coalesce
        interval: 50
        onTriggered: {
            if (root.pending < 0)
                return;
            const pct = Math.round(root.pending * 100);
            root.pending = -1;
            root.lastSetAt = Date.now();
            Quickshell.execDetached(["brightnessctl", "--class=backlight", "set", pct + "%"]);
        }
    }
}
