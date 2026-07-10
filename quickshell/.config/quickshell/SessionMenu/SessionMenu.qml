pragma ComponentBehavior: Bound
// Session menu (the wlogout that was installed but never configured):
// lock / logout / suspend / reboot / poweroff on a fullscreen scrim over
// the focused output. Toggled via `qs ipc call session toggle` (Mod+Shift+E).
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services
import qs.Theme

Scope {
    id: root

    property bool open: false

    function toggle() {
        open = !open;
    }

    component SessionButton: Rectangle {
        id: btn

        required property string icon
        required property string label
        required property var run

        width: 110
        height: 110
        radius: Theme.islandRadius
        color: area.containsMouse ? Theme.surface1 : Theme.alpha(Theme.surface0, 0.9)
        border.width: 1
        border.color: area.containsMouse ? Theme.mauve : Theme.surface1

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btn.icon
                font.family: Theme.fontFamily
                font.pixelSize: 30
                color: area.containsMouse ? Theme.mauve : Theme.text
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btn.label
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Theme.subtext0
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.open = false;
                btn.run();
            }
        }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput)
                ?? Quickshell.screens[0]
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Theme.alpha(Theme.crust, 0.6)

            // Esc or outside click closes
            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.open = false

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 16

                    SessionButton {
                        icon: "󰌾"
                        label: "lock"
                        run: () => Quickshell.execDetached(["hyprlock"])
                    }
                    SessionButton {
                        icon: "󰗽"
                        label: "logout"
                        run: () => Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"])
                    }
                    SessionButton {
                        icon: "󰤄"
                        label: "suspend"
                        run: () => Quickshell.execDetached(["systemctl", "suspend"])
                    }
                    SessionButton {
                        icon: "󰜉"
                        label: "reboot"
                        run: () => Quickshell.execDetached(["systemctl", "reboot"])
                    }
                    SessionButton {
                        icon: "󰐥"
                        label: "poweroff"
                        run: () => Quickshell.execDetached(["systemctl", "poweroff"])
                    }
                }
            }
        }
    }
}
