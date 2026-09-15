// One row of a drop-down menu or a settings list: optional glyph or image
// column, label, muted detail on the right (a keybind, "42%"), optional
// check/radio column and submenu chevron. Replaces the five near-identical
// row components the audio / tray / screen-tools menus used to carry.
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.Theme

Rectangle {
    id: root

    property string glyph: ""              // nerd glyph column
    property url icon                      // image column (tray entries, app icons)
    property string label: ""
    property string sublabel: ""           // second, smaller line under the label
    property string detail: ""             // right-aligned muted text
    property bool checkable: false         // show a check column
    property bool radio: false             // …drawn as a radio instead of a checkbox
    property bool checked: false
    property bool selected: false          // bold label (the current device, profile…)
    property bool hasSubmenu: false
    property bool rowEnabled: true         // not `enabled`: that would shadow Item's
    property color glyphColor: Theme.accent
    property bool busy: false              // spinner glyph instead of the chevron
    readonly property alias hovered: area.containsMouse
    default property alias trailing: trailingSlot.data

    signal triggered()

    width: parent ? parent.width : implicitWidth
    implicitHeight: sublabel !== "" ? Theme.rowHeight + 12 : Theme.rowHeight
    height: implicitHeight
    radius: Theme.radiusSmall
    color: !rowEnabled ? "transparent"
         : area.pressed ? Theme.statePressed
         : area.containsMouse ? Theme.stateHover
         : "transparent"
    opacity: rowEnabled ? 1 : Theme.disabledOpacity

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingSm
        anchors.rightMargin: Theme.spacingSm
        spacing: Theme.spacingSm

        Icon {
            visible: root.checkable
            glyph: root.radio
                ? (root.checked ? Icons.radioOn : Icons.radioOff)
                : (root.checked ? Icons.checked : Icons.unchecked)
            size: Theme.iconSizeSm
            color: root.checked ? Theme.accent : Theme.textMuted
        }

        Icon {
            visible: root.glyph !== ""
            glyph: root.glyph
            size: Theme.iconSizeSm
            color: root.glyphColor
        }

        IconImage {
            visible: root.icon.toString() !== ""
            source: root.icon
            implicitSize: Theme.iconSizeSm
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.label
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                font.weight: root.selected ? Theme.weightBold : Theme.weightRegular
                color: root.selected ? Theme.textPrimary : Theme.textSecondary
            }

            Text {
                Layout.fillWidth: true
                visible: root.sublabel !== ""
                text: root.sublabel
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                color: Theme.textHint
            }
        }

        Text {
            visible: root.detail !== ""
            text: root.detail
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            color: Theme.textHint
        }

        Item {
            id: trailingSlot
            visible: children.length > 0
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }

        Icon {
            visible: root.hasSubmenu || root.busy
            glyph: root.busy ? Icons.refresh : Icons.chevronRight
            size: Theme.iconSizeSm
            color: Theme.textMuted

            RotationAnimation on rotation {
                running: root.busy
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 1200
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.rowEnabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
