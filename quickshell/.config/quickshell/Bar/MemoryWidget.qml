// Memory usage (used = total - available, like waybar) — pure view over the
// SysInfo singleton; see Services/SysInfo.qml for why the sampling moved out.
import QtQuick
import qs.Services
import qs.Theme

BarText {
    readonly property real pct: SysInfo.memPct

    text: "  " + (pct < 0 ? "--" : Math.round(pct)) + "%"
    color: Theme.loadColor(pct)
    tip: SysInfo.memTip
}
