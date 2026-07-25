pragma ComponentBehavior: Bound
// PolicyKit authentication agent, in-shell.
//
// Replaces polkit-mate-agent.service: an unthemed GTK dialog from a package
// installed for nothing else, supervised by a user unit that needed its own fix
// to stay up under niri. Only ONE agent can own a session, so
// polkit-mate-agent must be stopped for this to register — `registered` below
// is the thing to check if prompts stop appearing.
//
// Styled to match Lock/Lock.qml, since both are "prove who you are" surfaces.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import qs.Services
import qs.Theme

Scope {
    id: root

    readonly property bool registered: agent.isRegistered
    readonly property var flow: agent.flow

    PolkitAgent {
        id: agent
    }

    onRegisteredChanged: {
        if (!registered)
            console.warn("polkit: agent not registered — is polkit-mate-agent still running?");
    }

    LazyLoader {
        active: root.flow !== null

        PanelWindow {
            id: win

            readonly property var flow: root.flow

            screen: Niri.focusedScreen
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            // keyboard has to be ours: the user is about to type a password
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Theme.alpha(Theme.crust, 0.6)

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: win.flow?.cancelAuthenticationRequest()

                Rectangle {
                    anchors.centerIn: parent
                    width: 460
                    height: content.implicitHeight + 48
                    radius: Theme.islandRadius
                    color: Theme.alpha(Theme.base, 0.98)
                    border.width: 1
                    border.color: Theme.surface0

                    Column {
                        id: content
                        anchors.centerIn: parent
                        width: parent.width - 48
                        spacing: 14

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "󰒃  authentication required"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 3
                            font.weight: Font.Bold
                            color: Theme.mauve
                        }

                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            text: win.flow?.message ?? ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.text
                        }

                        // which action is being authorised — useful for spotting
                        // a prompt you did not expect
                        Text {
                            width: parent.width
                            visible: (win.flow?.actionId ?? "") !== ""
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideMiddle
                            text: win.flow?.actionId ?? ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                            color: Theme.overlay1
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: win.flow?.isResponseRequired ?? false
                            width: 300
                            height: 46
                            radius: 12
                            color: Theme.surface0
                            border.width: 2
                            border.color: (win.flow?.supplementaryIsError ?? false)
                                ? Theme.red : Theme.mauve

                            TextInput {
                                id: field
                                anchors.fill: parent
                                anchors.margins: 12
                                focus: true
                                // polkit tells us whether this response is a
                                // secret (password) or plain (e.g. a token id)
                                echoMode: (win.flow?.responseVisible ?? false)
                                    ? TextInput.Normal : TextInput.Password
                                passwordCharacter: "•"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize + 1
                                color: Theme.text
                                verticalAlignment: TextInput.AlignVCenter
                                horizontalAlignment: TextInput.AlignHCenter

                                onAccepted: {
                                    if (text === "")
                                        return;
                                    win.flow?.submit(text);
                                    text = "";
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: field.text === ""
                                text: win.flow?.inputPrompt ?? "password…"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.italic: true
                                color: Theme.overlay0
                            }
                        }

                        Text {
                            width: parent.width
                            visible: (win.flow?.supplementaryMessage ?? "") !== ""
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: win.flow?.supplementaryMessage ?? ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: (win.flow?.supplementaryIsError ?? false)
                                ? Theme.red : Theme.subtext0
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "enter to confirm · esc to cancel"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                            color: Theme.overlay0
                        }
                    }
                }
            }
        }
    }
}
