// Text button. `kind`: "primary" (accent fill), "ghost" (outline), "danger".
// Uses Item.enabled directly — that is the real property, and children inherit
// it, so the MouseArea disables with it for free.
import QtQuick
import qs.Theme

Rectangle {
    id: root

    property string text: ""
    property string glyph: ""
    property string kind: "ghost"
    property bool compact: false
    readonly property bool primary: kind === "primary"
    readonly property bool danger: kind === "danger"
    readonly property alias hovered: area.containsMouse

    signal clicked()

    implicitHeight: compact ? 26 : 32
    implicitWidth: row.implicitWidth + (compact ? 20 : 28)
    radius: height / 2   // pill
    opacity: enabled ? 1 : Theme.disabledOpacity
    color: primary ? (area.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent)
         : danger ? (area.containsMouse ? Theme.alpha(Theme.error, 0.25) : Theme.alpha(Theme.error, 0.12))
         : area.pressed ? Theme.statePressed
         : area.containsMouse ? Theme.stateHover
         : "transparent"
    border.width: primary ? 0 : 1
    border.color: danger ? Theme.alpha(Theme.error, 0.6) : Theme.outline

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingXs

        Icon {
            visible: root.glyph !== ""
            anchors.verticalCenter: parent.verticalCenter
            glyph: root.glyph
            size: Theme.iconSizeSm
            color: label.color
        }

        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            visible: root.text !== ""
            text: root.text
            font.family: Theme.fontFamily
            font.pixelSize: root.compact ? Theme.fontSmall : Theme.fontLabel
            font.weight: Theme.weightMedium
            color: root.primary ? Theme.onAccent : root.danger ? Theme.error : Theme.textPrimary
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
