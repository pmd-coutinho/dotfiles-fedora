// Drawer header: avatar, user, host · uptime, battery pill, power button.
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs.Components
import qs.Services
import qs.Theme

RowLayout {
    id: row

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property int pct: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool charging: battery && battery.state === UPowerDeviceState.Charging

    spacing: Theme.spacingSm

    // uptime only ticks while the drawer is open
    Timer {
        interval: 60000
        repeat: true
        running: Notifs.panelOpen
        triggeredOnStart: true
        onTriggered: User.refreshUptime()
    }

    ClippingRectangle {
        implicitWidth: 40
        implicitHeight: 40
        radius: 20
        color: Theme.accent

        Image {
            anchors.fill: parent
            visible: User.avatarUrl !== ""
            source: User.avatarUrl
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(80, 80)
        }

        Text {
            anchors.centerIn: parent
            visible: User.avatarUrl === ""
            text: User.initial
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLarge
            font.weight: Theme.weightBold
            color: Theme.onAccent
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
            Layout.fillWidth: true
            text: User.fullName
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMedium
            font.weight: Theme.weightBold
            color: Theme.textPrimary
        }

        Text {
            Layout.fillWidth: true
            text: [User.hostname, User.uptimeText].filter(s => s !== "").join(" · ")
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            color: Theme.textHint
        }
    }

    Rectangle {
        visible: row.hasBattery
        implicitHeight: 26
        implicitWidth: batt.implicitWidth + 2 * Theme.spacingSm
        radius: height / 2
        color: Theme.surfaceRaised

        Row {
            id: batt
            anchors.centerIn: parent
            spacing: Theme.spacingXs

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                glyph: Icons.battery(row.pct, row.charging)
                size: Theme.iconSizeSm
                color: row.charging ? Theme.yellow : row.pct <= 10 ? Theme.error : row.pct <= 25 ? Theme.warning : Theme.success
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: row.pct + "%"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.weight: Theme.weightMedium
                color: Theme.textSecondary
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Bus.controlCenter?.push("power")
        }
    }

    Rectangle {
        implicitWidth: 32
        implicitHeight: 32
        radius: 16
        color: powerArea.containsMouse ? Theme.alpha(Theme.error, 0.18) : Theme.surfaceRaised

        Icon {
            anchors.centerIn: parent
            glyph: Icons.poweroff
            color: powerArea.containsMouse ? Theme.error : Theme.textSecondary
        }
        MouseArea {
            id: powerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Notifs.panelOpen = false;
                Bus.sessionMenu?.toggle();
            }
        }
    }
}
