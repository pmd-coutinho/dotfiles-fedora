pragma ComponentBehavior: Bound
// Session lock (ext-session-lock + PAM) — port of the hyprlock look:
// blurred/dimmed background, big clock, date, mauve input pill.
//
// NOT yet wired to idle/before-sleep/keybinds — hyprlock remains the
// active locker until this has survived a week of manual testing
// (quickshell-mirror#503: crash history with monitor power-off under
// niri while locked). Test with `qs ipc call lock lock` and keep a
// spare TTY (Ctrl+Alt+F3): if the shell dies while locked, niri keeps
// the session locked and you unlock from the TTY (`niri msg action
// do-screen-transition` won't help — restart qs from the TTY instead).
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.Theme

Scope {
    id: root

    property bool locked: false
    property string password: ""
    property int attempts: 0
    property bool failed: false
    property bool checking: false

    function lock() {
        attempts = 0;
        failed = false;
        locked = true;
    }

    function tryUnlock(pw) {
        if (checking)
            return;
        password = pw;
        checking = true;
        pam.start();
    }

    PamContext {
        id: pam

        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }
        onCompleted: result => {
            root.checking = false;
            root.password = "";
            if (result === PamResult.Success) {
                root.locked = false;
                root.failed = false;
            } else {
                root.attempts += 1;
                root.failed = true;
            }
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: root.locked

        WlSessionLockSurface {
            id: surface

            color: Theme.crust

            Image {
                id: bg
                anchors.fill: parent
                source: Quickshell.env("HOME") + "/Pictures/wallpapers/cat-waves.png"
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: bg
                blurEnabled: true
                blur: 1.0
                blurMax: 48
                brightness: -0.35
            }

            SystemClock {
                id: clock
                // minute granularity: per-second redraws keep powered-off
                // monitors from staying off (same gotcha as hyprlock)
                precision: SystemClock.Minutes
            }

            Column {
                anchors.centerIn: parent
                spacing: 24

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.family: Theme.fontFamily
                    font.pixelSize: 96
                    font.weight: Font.Bold
                    color: Theme.text
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, dd MMMM")
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    color: Theme.subtext0
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 280
                    height: 52
                    radius: 12
                    color: Theme.surface0
                    border.width: 2
                    border.color: root.failed ? Theme.red
                                : root.checking ? Theme.green
                                : Theme.mauve

                    TextInput {
                        id: passwordField
                        anchors.fill: parent
                        anchors.margins: 14
                        focus: true
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 2
                        color: Theme.text
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        enabled: !root.checking

                        onTextChanged: root.failed = false
                        onAccepted: {
                            if (text !== "") {
                                root.tryUnlock(text);
                                text = "";
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: passwordField.text === "" && !root.failed
                        text: "password…"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.italic: true
                        color: Theme.overlay0
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.failed && passwordField.text === ""
                        text: "nope (" + root.attempts + ")"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.italic: true
                        color: Theme.red
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "  " + Quickshell.env("USER")
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: Theme.subtext0
                }
            }
        }
    }
}
