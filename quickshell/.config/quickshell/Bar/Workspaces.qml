pragma ComponentBehavior: Bound
// Named-workspace pills for this output (waybar niri/workspaces port):
// text labels per workspace, active pill stretches and fills mauve.
import QtQuick
import Quickshell
import qs.Services
import qs.Theme

Row {
    id: root

    property string output

    // workspace name → label (same map as the old waybar format-icons)
    readonly property var labels: ({
        "1-slack": "slack",
        "2-telegram": "telegram",
        "3-firefox": "firefox",
        "4-laptop": "4",
        "5-term": "term",
        "6-code": "code",
        "7-rider": "rider",
        "8-giga": "8",
        "9-vivaldi": "vivaldi",
        "10-obsidian": "obsidian"
    })

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    spacing: 4
    leftPadding: 2
    rightPadding: 2

    // Niri.workspacesOn() returns a fresh array on every compositor event, so a
    // plain `model:` binding tore down and rebuilt every delegate — which is why
    // the width Behavior below never actually animated and hover state reset on
    // each switch. ScriptModel diffs by `id` and keeps the delegates alive.
    ScriptModel {
        id: workspaceModel
        objectProp: "id"
        values: Niri.workspacesOn(root.output)
    }

    Repeater {
        model: workspaceModel

        Rectangle {
            id: pill

            required property var modelData
            readonly property bool active: modelData.is_active
            readonly property bool urgent: modelData.is_urgent ?? false

            anchors.verticalCenter: parent.verticalCenter
            height: Theme.barHeight - 8
            width: label.implicitWidth + (active ? 28 : 14)
            radius: 8
            color: urgent ? Theme.red
                 : active ? Theme.mauve
                 : mouse.containsMouse ? Theme.surface0
                 : "transparent"

            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                }
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: root.labels[pill.modelData.name] ?? pill.modelData.name ?? "·"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Medium
                color: (pill.active || pill.urgent) ? Theme.crust
                     : mouse.containsMouse ? Theme.text
                     : Theme.overlay0
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Niri.focusWorkspace(pill.modelData)
            }
        }
    }
}
