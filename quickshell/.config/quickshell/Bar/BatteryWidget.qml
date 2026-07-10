// Battery via native UPower; critical-and-discharging blinks like the old
// waybar keyframes.
import QtQuick
import Quickshell.Services.UPower
import qs.Theme

BarText {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property int pct: Math.round((dev?.percentage ?? 0) * 100)
    // only true while actually charging — full/pending-charge on AC shows the
    // plain green battery, matching the old waybar behavior
    readonly property bool charging: dev && dev.state === UPowerDeviceState.Charging
    readonly property bool critical: !charging && pct <= 10
    readonly property var icons: ["󰁺", "󰁻", "󰁽", "󰁿", "󰂁", "󰁹"]

    property bool flash: false

    visible: dev?.isLaptopBattery ?? false
    text: (charging ? "󰂄" : icons[Math.min(5, Math.floor(pct / 100 * 6))]) + "  " + pct + "%"
    color: flash ? Theme.crust
         : charging ? Theme.yellow
         : critical ? Theme.red
         : pct <= 25 ? Theme.peach
         : Theme.green

    tip: {
        if (!dev)
            return "";
        const secs = charging ? dev.timeToFull : dev.timeToEmpty;
        if (!secs || secs <= 0)
            return pct + "%";
        const h = Math.floor(secs / 3600);
        const m = Math.round((secs % 3600) / 60);
        return h + "h " + m + "m " + (charging ? "until full" : "remaining");
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        z: -1
        radius: 8
        color: root.flash ? Theme.red : "transparent"
    }

    Timer {
        interval: 500
        running: root.critical
        repeat: true
        onTriggered: root.flash = !root.flash
        onRunningChanged: if (!running) root.flash = false
    }
}
