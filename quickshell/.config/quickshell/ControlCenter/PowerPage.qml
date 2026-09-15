pragma ComponentBehavior: Bound
// Power profile + battery details (native power-profiles-daemon and UPower
// bindings; there is deliberately no powerprofilesctl on this machine).
import QtQuick
import Quickshell.Services.UPower
import qs.Components
import qs.Theme

Page {
    id: page

    title: "Power"

    readonly property var dev: UPower.displayDevice
    readonly property bool hasBattery: dev?.isLaptopBattery ?? false

    function fmtSecs(s) {
        if (!s || s <= 0)
            return "";
        const h = Math.floor(s / 3600);
        const m = Math.round((s % 3600) / 60);
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }

    function stateName(s) {
        switch (s) {
        case UPowerDeviceState.Charging: return "charging";
        case UPowerDeviceState.Discharging: return "on battery";
        case UPowerDeviceState.FullyCharged: return "full";
        case UPowerDeviceState.PendingCharge: return "plugged in, not charging";
        case UPowerDeviceState.PendingDischarge: return "pending discharge";
        case UPowerDeviceState.Empty: return "empty";
        default: return "unknown";
        }
    }

    component Row_: Item {
        property string key: ""
        property string value: ""
        width: parent.width
        height: value !== "" ? 26 : 0
        visible: value !== ""

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingSm
            anchors.verticalCenter: parent.verticalCenter
            text: parent.key
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.textSecondary
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingSm
            anchors.verticalCenter: parent.verticalCenter
            text: parent.value
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            font.weight: Theme.weightMedium
            color: Theme.textPrimary
        }
    }

    SectionHeader { text: "profile" }

    Repeater {
        model: [
            { p: PowerProfile.Performance, label: "Performance", glyph: Icons.profilePerformance, show: PowerProfiles.hasPerformanceProfile },
            { p: PowerProfile.Balanced, label: "Balanced", glyph: Icons.profileBalanced, show: true },
            { p: PowerProfile.PowerSaver, label: "Power saver", glyph: Icons.profileSaver, show: true }
        ]

        MenuRow {
            required property var modelData
            visible: modelData.show
            checkable: true
            radio: true
            checked: PowerProfiles.profile === modelData.p
            selected: checked
            glyph: modelData.glyph
            glyphColor: checked ? Theme.accent : Theme.textMuted
            label: modelData.label
            onTriggered: PowerProfiles.profile = modelData.p
        }
    }

    Text {
        width: parent.width
        visible: (PowerProfiles.degradationReason ?? PerformanceDegradationReason.None) !== PerformanceDegradationReason.None
        leftPadding: Theme.spacingSm
        wrapMode: Text.Wrap
        text: "performance is being held back: " + PerformanceDegradationReason.toString(PowerProfiles.degradationReason)
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        color: Theme.warning
    }

    SectionHeader {
        visible: page.hasBattery
        text: "battery"
    }

    Column {
        width: parent.width
        visible: page.hasBattery

        Row_ { key: "charge"; value: Math.round((page.dev?.percentage ?? 0) * 100) + "%" }
        Row_ { key: "state"; value: page.stateName(page.dev?.state) }
        Row_ {
            key: page.dev?.state === UPowerDeviceState.Charging ? "until full" : "remaining"
            value: page.fmtSecs(page.dev?.state === UPowerDeviceState.Charging ? page.dev?.timeToFull : page.dev?.timeToEmpty)
        }
        Row_ {
            key: "health"
            value: (page.dev?.healthSupported ?? false) ? Math.round(page.dev.healthPercentage) + "%" : ""
        }
        Row_ {
            key: page.dev?.state === UPowerDeviceState.Charging ? "charge rate" : "draw"
            value: (page.dev?.changeRate ?? 0) > 0 ? page.dev.changeRate.toFixed(1) + " W" : ""
        }
    }
}
