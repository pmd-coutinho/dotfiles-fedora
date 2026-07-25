pragma Singleton
// CPU + memory sampling, once for the whole shell.
//
// These readings used to live inside the bar widgets, which sit inside Bar.qml's
// Variants delegate — so with three monitors there were three /proc/stat readers
// each keeping their OWN previous-sample state, and the bars could legitimately
// disagree about CPU usage. Three /proc/meminfo timers too. Worse, both used
// `blockLoading: true` + `waitForJob()`, i.e. synchronous UI-thread file I/O
// every 5s per monitor.
//
// One timer, one sample, async reads. The widgets are pure views now.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // 0..100, -1 until the first pair of samples has been taken (CPU usage is a
    // delta, so the very first tick can only record a baseline). Widgets treat
    // negative as "no reading yet" rather than rendering a bogus 0% — or the
    // NaN% the old code produced when a read failed.
    readonly property real cpuPct: _cpuPct
    readonly property real memPct: totalKb > 0 ? 100 * usedKb / totalKb : -1
    readonly property real totalKb: _totalKb
    readonly property real usedKb: _usedKb

    property real _cpuPct: -1
    property real _totalKb: 0
    property real _usedKb: 0
    // previous /proc/stat totals; null until the first successful read
    property var _prev: null

    readonly property string memTip: totalKb > 0
        ? (usedKb / 1048576).toFixed(1) + " GiB / " + (totalKb / 1048576).toFixed(1) + " GiB"
        : ""

    FileView {
        id: stat
        path: "/proc/stat"

        onLoaded: {
            // "cpu  <user> <nice> <system> <idle> <iowait> ..." — aggregate line
            const line = text().split("\n")[0] ?? "";
            const parts = line.trim().split(/\s+/).slice(1).map(Number);
            // a short/garbled read would otherwise propagate as NaN into the bar
            if (parts.length < 5 || parts.some(isNaN))
                return;
            const idle = parts[3] + parts[4];
            const total = parts.reduce((a, b) => a + b, 0);
            if (root._prev && total > root._prev.total)
                root._cpuPct = 100 * (1 - (idle - root._prev.idle) / (total - root._prev.total));
            root._prev = { total: total, idle: idle };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"

        // built once, not per field per tick like the old inline widget did
        readonly property var fieldRe: ({
            total: /MemTotal:\s+(\d+)/,
            available: /MemAvailable:\s+(\d+)/
        })

        onLoaded: {
            const t = text();
            const total = Number(t.match(fieldRe.total)?.[1] ?? 0);
            const available = Number(t.match(fieldRe.available)?.[1] ?? 0);
            if (total <= 0)
                return;
            root._totalKb = total;
            root._usedKb = total - available;
        }
    }

    Timer {
        interval: 5000   // the old waybar interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
        }
    }
}
