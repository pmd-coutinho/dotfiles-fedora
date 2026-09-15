// icon-button · slider · percentage · optional chevron. The icon click is the
// mute toggle for audio rows; the chevron opens the row's sub-page.
import QtQuick
import QtQuick.Layouts
import qs.Components
import qs.Theme

RowLayout {
    id: row

    property string glyph: ""
    property real value: 0
    property bool muted: false
    property color color: Theme.accent
    property bool chevron: false
    property bool rowEnabled: true

    signal moved(real value)
    signal iconClicked()
    signal chevronClicked()

    implicitHeight: Theme.controlHeight
    spacing: Theme.spacingSm
    opacity: rowEnabled ? 1 : Theme.disabledOpacity

    Rectangle {
        implicitWidth: 28
        implicitHeight: 28
        radius: 14
        color: iconArea.containsMouse ? Theme.stateHover : "transparent"

        Icon {
            anchors.centerIn: parent
            glyph: row.glyph
            color: row.muted ? Theme.textMuted : row.color
        }
        MouseArea {
            id: iconArea
            anchors.fill: parent
            enabled: row.rowEnabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.iconClicked()
        }
    }

    SliderBar {
        Layout.fillWidth: true
        value: row.value
        interactive: row.rowEnabled
        color: row.muted ? Theme.textMuted : row.color
        onMoved: v => row.moved(v)
    }

    Text {
        Layout.preferredWidth: 38
        horizontalAlignment: Text.AlignRight
        text: row.muted ? "mute" : Math.round(row.value * 100) + "%"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        color: Theme.textHint
    }

    Rectangle {
        visible: row.chevron
        implicitWidth: 24
        implicitHeight: 24
        radius: 12
        color: chevArea.containsMouse ? Theme.stateHover : "transparent"

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
            onClicked: row.chevronClicked()
        }
    }
}
