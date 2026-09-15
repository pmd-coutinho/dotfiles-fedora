// Pill switch. Controlled: it reports `toggled()` and the owner flips the
// state, so a switch bound to a service can never drift from it.
import QtQuick
import qs.Theme

Rectangle {
    id: root

    property bool checked: false
    property bool switchEnabled: true      // not `enabled`: that would shadow Item's

    signal toggled()

    implicitWidth: 44
    implicitHeight: 22
    radius: height / 2   // pill
    color: checked ? Theme.accent : Theme.surface1
    opacity: switchEnabled ? 1 : Theme.disabledOpacity

    Behavior on color {
        ColorAnimation { duration: Theme.durationShort }
    }

    Rectangle {
        width: 16
        height: 16
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 3 : 3
        color: root.checked ? Theme.onAccent : Theme.overlay1

        Behavior on x {
            NumberAnimation { duration: Theme.durationShort; easing.type: Theme.easeStandard }
        }
        Behavior on color {
            ColorAnimation { duration: Theme.durationShort }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4   // easier target than the 22px pill alone
        enabled: root.switchEnabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
