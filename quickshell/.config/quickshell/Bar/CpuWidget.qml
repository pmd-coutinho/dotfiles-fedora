// CPU load as a ring — pure view over the SysInfo singleton, which samples once
// for the whole shell. Click opens btop.
import QtQuick
import Quickshell
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    readonly property real usage: SysInfo.cpuPct

    tip: usage < 0 ? "cpu" : "cpu " + Math.round(usage) + "%"
    hint: "click: btop"

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: Icons.cpu
        color: Theme.loadColor(usage)
    }

    Ring {
        anchors.verticalCenter: parent.verticalCenter
        value: usage / 100
        color: Theme.loadColor(usage)
    }

    onClicked: button => {
        if (button === Qt.LeftButton)
            Quickshell.execDetached(["ghostty", "-e", "btop"]);
    }
}
