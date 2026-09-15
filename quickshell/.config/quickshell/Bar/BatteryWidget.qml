// Battery via native UPower. Critical-and-discharging breathes a red wash
// (not the 2 Hz strobe it used to be). Click opens the control center's power
// page.
import QtQuick
import Quickshell.Services.UPower
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property int pct: Math.round((dev?.percentage ?? 0) * 100)
    // only true while actually charging — full/pending-charge on AC shows the
    // plain green battery
    readonly property bool charging: dev && dev.state === UPowerDeviceState.Charging
    readonly property bool critical: !charging && pct <= 10
    readonly property color tint: charging ? Theme.yellow
                                : critical ? Theme.error
                                : pct <= 25 ? Theme.warning
                                : Theme.success

    property real pulse: 0

    shown: dev?.isLaptopBattery ?? false
    wash: critical ? Theme.alpha(Theme.error, pulse) : "transparent"

    SequentialAnimation on pulse {
        running: root.critical
        loops: Animation.Infinite
        NumberAnimation { to: 0.35; duration: Theme.durationPulse; easing.type: Easing.InOutQuad }
        NumberAnimation { to: 0.08; duration: Theme.durationPulse; easing.type: Easing.InOutQuad }
        onRunningChanged: if (!running) root.pulse = 0
    }

    tip: {
        if (!dev)
            return "";
        const secs = charging ? dev.timeToFull : dev.timeToEmpty;
        const state = charging ? "charging" : dev.state === UPowerDeviceState.FullyCharged ? "full" : "on battery";
        if (!secs || secs <= 0)
            return pct + "% · " + state;
        const h = Math.floor(secs / 3600);
        const m = Math.round((secs % 3600) / 60);
        return pct + "% · " + h + "h " + m + "m " + (charging ? "until full" : "remaining");
    }
    hint: "click: power settings"

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: Icons.battery(root.pct, root.charging)
        color: root.tint
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.pct + "%"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontLabel
        font.weight: Theme.weightMedium
        color: root.tint
    }

    onClicked: button => {
        if (button === Qt.LeftButton)
            Bus.controlCenter?.open("power");
    }
}
