// CPU usage — pure view over the SysInfo singleton, which samples once for the
// whole shell (this widget used to sample once per monitor, with per-monitor
// previous-sample state, so the bars could disagree).
import QtQuick
import qs.Services
import qs.Theme

BarText {
    readonly property real usage: SysInfo.cpuPct

    text: "  " + (usage < 0 ? "--" : Math.round(usage)) + "%"
    color: Theme.loadColor(usage)
}
