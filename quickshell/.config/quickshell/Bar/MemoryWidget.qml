// Memory usage from /proc/meminfo (used = total - available, like waybar).
import QtQuick
import Quickshell.Io
import qs.Theme

BarText {
    id: root

    property real totalKb: 0
    property real usedKb: 0
    readonly property real pct: totalKb > 0 ? 100 * usedKb / totalKb : 0

    text: "  " + Math.round(pct) + "%"
    color: pct >= 90 ? Theme.red : pct >= 70 ? Theme.peach : Theme.subtext0
    tip: (usedKb / 1048576).toFixed(1) + " GiB / " + (totalKb / 1048576).toFixed(1) + " GiB"

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        blockLoading: true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            meminfo.reload();
            meminfo.waitForJob();
            const text = meminfo.text();
            const grab = name => Number(text.match(new RegExp(name + ":\\s+(\\d+)"))?.[1] ?? 0);
            root.totalKb = grab("MemTotal");
            root.usedKb = root.totalKb - grab("MemAvailable");
        }
    }
}
