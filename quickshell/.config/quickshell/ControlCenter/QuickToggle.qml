// A quick-settings tile: icon in a circle (accent when active), label, a live
// subtitle (SSID, "until 14:30", "4000 K") and, when the setting has a page,
// a separate chevron target so tapping the tile toggles and the chevron opens.
import QtQuick
import QtQuick.Layouts
import qs.Components
import qs.Theme

Rectangle {
    id: tile

    property string glyph: ""
    property string label: ""
    property string subtitle: ""
    property bool active: false
    property bool toggleEnabled: true
    property bool hasPage: false

    signal toggled()
    signal opened()

    implicitHeight: 58
    radius: Theme.radiusMedium
    color: active ? Theme.accentSubtle : Theme.surfaceRaised
    border.width: 1
    border.color: active ? Theme.alpha(Theme.accent, 0.5) : "transparent"
    opacity: toggleEnabled ? 1 : Theme.disabledOpacity

    Behavior on color {
        ColorAnimation { duration: Theme.durationShort }
    }

    // hover wash over the whole tile
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: mainArea.pressed ? Theme.statePressed : mainArea.containsMouse ? Theme.stateHover : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.durationFast }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingSm
        anchors.rightMargin: tile.hasPage ? 0 : Theme.spacingSm
        spacing: Theme.spacingSm

        Rectangle {
            implicitWidth: 34
            implicitHeight: 34
            radius: 17
            color: tile.active ? Theme.accent : Theme.surface1

            Behavior on color {
                ColorAnimation { duration: Theme.durationShort }
            }

            Icon {
                anchors.centerIn: parent
                glyph: tile.glyph
                color: tile.active ? Theme.onAccent : Theme.textSecondary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: tile.label
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                font.weight: Theme.weightBold
                color: Theme.textPrimary
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: tile.subtitle
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                color: tile.active ? Theme.textSecondary : Theme.textHint
            }
        }

        Rectangle {
            visible: tile.hasPage
            Layout.fillHeight: true
            implicitWidth: 30
            color: chevArea.containsMouse ? Theme.stateHover : "transparent"
            topRightRadius: tile.radius
            bottomRightRadius: tile.radius

            Icon {
                anchors.centerIn: parent
                glyph: Icons.chevronRight
                size: Theme.iconSizeSm
                color: Theme.textMuted
            }
            MouseArea {
                id: chevArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tile.opened()
            }
        }
    }

    MouseArea {
        id: mainArea
        anchors.fill: parent
        anchors.rightMargin: tile.hasPage ? 30 : 0
        z: -1
        enabled: tile.toggleEnabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.toggled()
    }
}
