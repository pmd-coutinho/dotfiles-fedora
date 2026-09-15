// Horizontal level bar, optionally draggable (volume, brightness, media seek).
// Controlled like ToggleSwitch: `moved(value)` reports the user's intent, the
// owner writes it to the service, and `value` follows the service back.
//
// While the pointer is down `dragging` is true and the fill tracks the pointer
// directly, so the knob never fights a slow round-trip (sysfs echo, MPRIS).
import QtQuick
import qs.Theme

Item {
    id: root

    property real value: 0                 // 0..1
    property bool interactive: true
    property real thickness: 6
    property color color: Theme.accent
    property color trackColor: Theme.surface1
    // fraction past which the fill switches colour (volume over 100%); 0 = off
    property real overflowFrom: 0
    property color overflowColor: Theme.warning
    readonly property alias dragging: area.pressed
    readonly property alias hovered: area.containsMouse

    signal moved(real value)

    property real dragValue: 0
    readonly property real shownValue: dragging ? dragValue : Math.max(0, Math.min(1, value))

    implicitHeight: Math.max(thickness, Theme.hitMin)
    implicitWidth: 120

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.thickness
        radius: height / 2   // pill
        color: root.trackColor

        Rectangle {
            width: parent.width * root.shownValue
            height: parent.height
            radius: height / 2
            color: root.color

            Behavior on width {
                enabled: !root.dragging
                NumberAnimation { duration: Theme.durationFast }
            }
        }

        // the part above `overflowFrom` in the warning colour
        Rectangle {
            visible: root.overflowFrom > 0 && root.shownValue > root.overflowFrom
            x: parent.width * root.overflowFrom
            width: Math.max(0, parent.width * (root.shownValue - root.overflowFrom))
            height: parent.height
            radius: height / 2
            color: root.overflowColor
        }

        Rectangle {
            visible: root.overflowFrom > 0
            x: parent.width * root.overflowFrom - width / 2
            width: 1
            height: parent.height + 4
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textMuted
        }
    }

    // knob shows on hover/drag only, so a passive level bar stays a bar
    Rectangle {
        visible: root.interactive
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(parent.width - width, parent.width * root.shownValue - width / 2))
        width: root.thickness + 8
        height: width
        radius: width / 2
        color: Theme.textPrimary
        scale: (area.containsMouse || area.pressed) ? 1 : 0
        opacity: scale

        Behavior on scale {
            NumberAnimation { duration: Theme.durationShort; easing.type: Theme.easeEmphasized }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function valueAt(x) {
            return Math.max(0, Math.min(1, x / width));
        }
        onPressed: m => {
            root.dragValue = valueAt(m.x);
            root.moved(root.dragValue);
        }
        onPositionChanged: m => {
            if (!pressed)
                return;
            root.dragValue = valueAt(m.x);
            root.moved(root.dragValue);
        }
        onWheel: w => {
            const step = w.angleDelta.y > 0 ? 0.05 : -0.05;
            root.moved(Math.max(0, Math.min(1, root.value + step)));
        }
    }
}
