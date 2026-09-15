pragma ComponentBehavior: Bound
// Workspace pills for this output. Each pill shows the icons of the apps on
// that workspace (deduplicated, capped), the active one is filled with the
// wallpaper accent and carries its name; an empty workspace is just its short
// label in muted text. Click focuses, scrolling over the group steps through
// this output's workspaces, urgent pills breathe red.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components
import qs.Services
import qs.Theme

Row {
    id: root

    property var bar
    property string output
    readonly property int maxIcons: 4

    // workspace name → short label (the names carry an index prefix in niri)
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

    function labelFor(ws) {
        return labels[ws.name] ?? ws.name ?? String(ws.idx ?? "·");
    }

    spacing: Theme.barItemGap
    Layout.minimumWidth: implicitWidth

    // Niri.workspacesOn() returns a fresh array on every compositor event, so a
    // plain `model:` binding tore down and rebuilt every delegate — which is why
    // width animations never ran and hover state reset on each switch.
    // ScriptModel diffs by `id` and keeps the delegates alive.
    ScriptModel {
        id: workspaceModel
        objectProp: "id"
        values: Niri.workspacesOn(root.output)
    }

    // scroll anywhere over the group to step workspaces; touchpads flood
    // wheel events, so accumulate to a notch and rate-limit
    property int wheelAcc: 0

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (cooldown.running)
                return;
            root.wheelAcc += event.angleDelta.y;
            if (Math.abs(root.wheelAcc) < 120)
                return;
            Niri.focusWorkspaceRelative(root.output, root.wheelAcc < 0 ? 1 : -1);
            root.wheelAcc = 0;
            cooldown.restart();
        }
    }

    Timer {
        id: cooldown
        interval: 150
    }

    Repeater {
        model: workspaceModel

        Rectangle {
            id: pill

            required property var modelData
            readonly property bool active: modelData.is_active
            readonly property bool urgent: modelData.is_urgent ?? false
            readonly property var wins: Niri.windowsOn(modelData.id)
            // one icon per distinct app, capped
            readonly property var apps: {
                const seen = [];
                for (const w of wins) {
                    const a = w.app_id ?? "";
                    if (a !== "" && !seen.includes(a))
                        seen.push(a);
                }
                return seen;
            }
            readonly property bool hasWindows: wins.length > 0

            // tooltip via the bar's shared popup
            readonly property string tip: root.labelFor(modelData)
                + (hasWindows ? " · " + wins.length + " window" + (wins.length === 1 ? "" : "s") : " · empty")
            readonly property string hint: wins.slice(0, 4).map(w => w.title).filter(t => t).join("\n")

            anchors.verticalCenter: parent.verticalCenter
            height: Theme.barItemHeight
            width: inner.implicitWidth + 2 * (active || !hasWindows ? 10 : 7)
            radius: height / 2   // pill
            color: urgent ? Theme.error
                 : active ? Theme.accent
                 : mouse.pressed ? Theme.statePressed
                 : mouse.containsMouse ? Theme.stateHover
                 : "transparent"

            Behavior on width {
                NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easeEmphasized }
            }
            Behavior on color {
                ColorAnimation { duration: Theme.durationFast }
            }

            SequentialAnimation on opacity {
                running: pill.urgent
                loops: Animation.Infinite
                NumberAnimation { to: 0.45; duration: Theme.durationPulse; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: Theme.durationPulse; easing.type: Easing.InOutQuad }
                onRunningChanged: if (!running) pill.opacity = 1
            }

            Row {
                id: inner
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: ScriptModel {
                        values: pill.apps.slice(0, root.maxIcons)
                    }

                    AppIcon {
                        required property var modelData
                        // parent is null for a beat while the model churns
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        appId: modelData
                        opacity: pill.active ? 1 : 0.8
                    }
                }

                Text {
                    visible: pill.apps.length > root.maxIcons
                    anchors.verticalCenter: parent.verticalCenter
                    text: "+" + (pill.apps.length - root.maxIcons)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTiny
                    color: pill.active ? Theme.onAccent : Theme.textMuted
                }

                Text {
                    // name on the active pill; empty pills show it as their only content
                    visible: pill.active || !pill.hasWindows
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.labelFor(pill.modelData)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    font.weight: Theme.weightMedium
                    color: (pill.active || pill.urgent) ? Theme.onAccent
                         : mouse.containsMouse ? Theme.textPrimary
                         : Theme.textMuted
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(pill.modelData)
                onEntered: root.bar?.showTip(pill)
                onExited: root.bar?.hideTip(pill)
            }
        }
    }
}
