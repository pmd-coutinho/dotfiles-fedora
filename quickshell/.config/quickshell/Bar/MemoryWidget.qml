// Memory usage as a ring (used = total - available) — pure view over the
// SysInfo singleton; see Services/SysInfo.qml for why the sampling moved out.
import QtQuick
import Quickshell
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    readonly property real pct: SysInfo.memPct

    tip: pct < 0 ? "memory" : "memory " + Math.round(pct) + "% · " + SysInfo.memTip
    hint: "click: btop"

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: Icons.memory
        color: Theme.loadColor(pct)
    }

    Ring {
        anchors.verticalCenter: parent.verticalCenter
        value: pct / 100
        color: Theme.loadColor(pct)
    }

    onClicked: button => {
        if (button === Qt.LeftButton)
            Quickshell.execDetached(["ghostty", "-e", "btop"]);
    }
}
