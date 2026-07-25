pragma ComponentBehavior: Bound
// Notification control center (Mod+Shift+N) — replaces the swaync panel:
// DND, quick toggles (wifi / bluetooth / mic / lock), MPRIS, history.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
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
        radius: Theme.radiusMedium
        color: active ? Theme.mauve : Theme.surface0

        Text {
            anchors.centerIn: parent
            text: tbtn.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLarge
            color: tbtn.active ? Theme.crust : Theme.subtext0
        }
        MouseArea {
            anchors.fill: parent
            onClicked: tbtn.tapped()
        }
    }

    // `enabled` reflects the player's can* capability: a greyed-out button beats
    // one that silently does nothing (not every player supports every control)
    component MediaBtn: Text {
        id: mbtn
        signal tapped()
        property bool available: true
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontXLarge
        color: available ? Theme.pink : Theme.overlay0
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            enabled: mbtn.available
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

            // cover the whole area below the bar: clicking outside the
            // drawer dismisses the panel (bar itself stays interactive)
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Normal
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: Notifs.panelOpen = false
            }

            Rectangle {
                anchors {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                    topMargin: 6
                    rightMargin: 10
                    bottomMargin: 8
                }
                width: 420
                radius: Theme.islandRadius
                color: Theme.alpha(Theme.base, 0.96)
                border.width: 1
                border.color: Theme.surface0

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: Theme.spacingMd

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
                            radius: height / 2   // pill
                            color: Notifs.dnd ? Theme.mauve : Theme.surface1

                            Rectangle {
                                width: 16
                                height: 16
                                radius: Theme.radiusMedium
                                anchors.verticalCenter: parent.verticalCenter
                                x: Notifs.dnd ? parent.width - width - 3 : 3
                                color: Notifs.dnd ? Theme.crust : Theme.overlay1
                                Behavior on x {
                                    NumberAnimation { duration: Theme.durationShort }
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
                        spacing: Theme.spacingSm

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
                            label: Icons.mic(Pipewire.defaultAudioSource?.audio?.muted ?? true)
                            active: !(Pipewire.defaultAudioSource?.audio?.muted ?? true)
                            onTapped: if (Pipewire.defaultAudioSource?.audio) Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted
                        }
                        ToggleButton {
                            label: Icons.lock
                            onTapped: {
                                Notifs.panelOpen = false;
                                Session.lock();
                            }
                        }
                    }

                    // ── mpris ──
                    Rectangle {
                        // the shared current player (Services/Media.qml)
                        readonly property var player: Media.player

                        id: mpris
                        width: parent.width
                        height: 96
                        visible: player !== null
                        radius: Theme.radiusMedium
                        color: Theme.surface0

                        Row {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 10

                            ClippingRectangle {
                                width: 84
                                height: 84
                                radius: Theme.radiusMedium
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
                                spacing: Theme.spacingXs

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
                                    font.pixelSize: Theme.fontLabel
                                    color: Theme.subtext0
                                }
                                Row {
                                    spacing: Theme.spacingLg

                                    MediaBtn {
                                        text: "󰒮"
                                        available: mpris.player?.canGoPrevious ?? false
                                        onTapped: mpris.player?.previous()
                                    }
                                    MediaBtn {
                                        text: mpris.player?.isPlaying ? Icons.pause : Icons.play
                                        available: mpris.player?.canTogglePlaying ?? false
                                        onTapped: mpris.player?.togglePlaying()
                                    }
                                    MediaBtn {
                                        text: "󰒭"
                                        available: mpris.player?.canGoNext ?? false
                                        onTapped: mpris.player?.next()
                                    }

                                    // only shown when more than one player is
                                    // around; the card otherwise silently picked
                                    // an arbitrary one
                                    MediaBtn {
                                        visible: Media.players.length > 1
                                        text: "󰲸"
                                        font.pixelSize: Theme.fontMedium
                                        onTapped: Media.cycle()
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
                            font.pixelSize: Theme.fontMedium
                            font.weight: Font.Bold
                            color: Theme.text
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: clearLabel.implicitWidth + 20
                            height: 24
                            radius: Theme.radiusMedium
                            visible: Notifs.count > 0
                            color: clearArea.containsMouse ? Theme.surface1 : Theme.surface0

                            Text {
                                id: clearLabel
                                anchors.centerIn: parent
                                text: "Clear All"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
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
                    // keyed model so scroll position and delegate state survive
                    // a new notification arriving (groupList() returns a fresh
                    // array every time)
                    ScriptModel {
                        id: historyModel
                        objectProp: "key"
                        values: Notifs.historyGroups
                    }

                    ListView {
                        width: parent.width
                        height: parent.height - y
                        clip: true
                        spacing: Theme.spacingSm
                        model: historyModel

                        delegate: NotificationCard {
                            required property var modelData
                            notif: modelData.latest
                            group: modelData
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
