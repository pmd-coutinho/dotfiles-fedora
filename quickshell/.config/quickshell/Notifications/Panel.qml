pragma ComponentBehavior: Bound
// Notification control center (Mod+Shift+N) — replaces the swaync panel:
// DND, quick toggles (wifi / bluetooth / mic / lock), MPRIS, history.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import qs.Services
import qs.Theme

Scope {
    id: root

    component ToggleButton: Rectangle {
        id: tbtn
        property string label
        property bool active: false
        signal tapped()

        width: (parent.width - 24) / 4
        height: 40
        radius: 8
        color: active ? Theme.mauve : Theme.surface0

        Text {
            anchors.centerIn: parent
            text: tbtn.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 3
            color: tbtn.active ? Theme.crust : Theme.subtext0
        }
        MouseArea {
            anchors.fill: parent
            onClicked: tbtn.tapped()
        }
    }

    component MediaBtn: Text {
        id: mbtn
        signal tapped()
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 4
        color: Theme.pink
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            onClicked: mbtn.tapped()
        }
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSource ? [Pipewire.defaultAudioSource] : []
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            visible: Notifs.panelOpen && Niri.focusedOutput === modelData.name

            anchors {
                top: true
                right: true
                bottom: true
            }
            margins {
                top: 6
                right: 10
                bottom: 8
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            implicitWidth: 420

            Rectangle {
                anchors.fill: parent
                radius: Theme.islandRadius
                color: Theme.alpha(Theme.base, 0.96)
                border.width: 1
                border.color: Theme.surface0

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // ── do not disturb ──
                    Item {
                        width: parent.width
                        height: 28

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Do Not Disturb"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight: Font.Bold
                            color: Theme.text
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 44
                            height: 22
                            radius: 11
                            color: Notifs.dnd ? Theme.mauve : Theme.surface1

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                anchors.verticalCenter: parent.verticalCenter
                                x: Notifs.dnd ? parent.width - width - 3 : 3
                                color: Notifs.dnd ? Theme.crust : Theme.overlay1
                                Behavior on x {
                                    NumberAnimation { duration: 150 }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Notifs.dnd = !Notifs.dnd
                            }
                        }
                    }

                    // ── quick toggles (old swaync buttons-grid) ──
                    Row {
                        width: parent.width
                        spacing: 8

                        ToggleButton {
                            label: "󰖩"
                            active: Networking.wifiEnabled
                            onTapped: Networking.wifiEnabled = !Networking.wifiEnabled
                        }
                        ToggleButton {
                            label: "󰂯"
                            active: Bluetooth.defaultAdapter?.enabled ?? false
                            onTapped: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                        }
                        ToggleButton {
                            label: "󰍬"
                            active: !(Pipewire.defaultAudioSource?.audio?.muted ?? true)
                            onTapped: if (Pipewire.defaultAudioSource?.audio) Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted
                        }
                        ToggleButton {
                            label: "󰌾"
                            onTapped: {
                                Notifs.panelOpen = false;
                                Quickshell.execDetached(["hyprlock"]);
                            }
                        }
                    }

                    // ── mpris ──
                    Rectangle {
                        readonly property var player: Mpris.players.values[0] ?? null

                        id: mpris
                        width: parent.width
                        height: 96
                        visible: player !== null
                        radius: 8
                        color: Theme.surface0

                        Row {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 10

                            ClippingRectangle {
                                width: 84
                                height: 84
                                radius: 8
                                color: Theme.surface1

                                Image {
                                    anchors.fill: parent
                                    source: mpris.player?.trackArtUrl ?? ""
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }

                            Column {
                                width: parent.width - 84 - 20
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    width: parent.width
                                    text: mpris.player?.trackTitle ?? ""
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.weight: Font.Bold
                                    color: Theme.text
                                }
                                Text {
                                    width: parent.width
                                    text: mpris.player?.trackArtist ?? ""
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize - 1
                                    color: Theme.subtext0
                                }
                                Row {
                                    spacing: 16

                                    MediaBtn {
                                        text: "󰒮"
                                        onTapped: mpris.player?.previous()
                                    }
                                    MediaBtn {
                                        text: mpris.player?.isPlaying ? "󰏤" : "󰐊"
                                        onTapped: mpris.player?.togglePlaying()
                                    }
                                    MediaBtn {
                                        text: "󰒭"
                                        onTapped: mpris.player?.next()
                                    }
                                }
                            }
                        }
                    }

                    // ── title + clear all ──
                    Item {
                        width: parent.width
                        height: 28

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Notifications"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 1
                            font.weight: Font.Bold
                            color: Theme.text
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: clearLabel.implicitWidth + 20
                            height: 24
                            radius: 8
                            visible: Notifs.count > 0
                            color: clearArea.containsMouse ? Theme.surface1 : Theme.surface0

                            Text {
                                id: clearLabel
                                anchors.centerIn: parent
                                text: "Clear All"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                color: Theme.text
                            }
                            MouseArea {
                                id: clearArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Notifs.clearAll()
                            }
                        }
                    }

                    // ── history ──
                    ListView {
                        width: parent.width
                        height: parent.height - y
                        clip: true
                        spacing: 8
                        model: [...Notifs.server.trackedNotifications.values].reverse()

                        delegate: NotificationCard {
                            required property var modelData
                            notif: modelData
                            width: ListView.view.width
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: Notifs.count === 0
                            text: "no notifications"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.overlay0
                        }
                    }
                }
            }
        }
    }
}
