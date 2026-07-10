// CPU usage from /proc/stat deltas — no shell exec, FileView re-read on a
// 5s tick like the old waybar interval.
import QtQuick
import Quickshell.Io
import qs.Theme

BarText {
    id: root

    property real usage: 0
    property var prev: null

    text: "  " + Math.round(usage) + "%"
    color: usage >= 90 ? Theme.red : usage >= 70 ? Theme.peach : Theme.subtext0

    FileView {
        id: stat
        path: "/proc/stat"
        blockLoading: true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            stat.waitForJob();
            const parts = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = parts[3] + (parts[4] ?? 0);
            const total = parts.reduce((a, b) => a + b, 0);
            if (root.prev && total > root.prev.total)
                root.usage = 100 * (1 - (idle - root.prev.idle) / (total - root.prev.total));
            root.prev = { total: total, idle: idle };
        }
    }
}
