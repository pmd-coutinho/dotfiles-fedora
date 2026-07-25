pragma ComponentBehavior: Bound
// Session lock (ext-session-lock + PAM) — port of the hyprlock look:
// blurred/dimmed background, big clock, date, mauve input pill.
//
// This is now the active locker (idle, before-sleep and Super+Alt+L all route
// here via Services/Session.qml). Escape hatch if the shell ever dies while
// locked: niri keeps the session locked, so switch to a TTY (Ctrl+Alt+F3) and
// restart quickshell from there — `niri msg action do-screen-transition`
// won't help. Watch for quickshell-mirror#503 (monitor power-off while locked).
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.Services
import qs.Theme

Scope {
    id: root

    // Session owns the lock state; this component is its view.
    readonly property bool locked: Session.locked
    property string password: ""
    property int attempts: 0
    property bool failed: false
    property bool checking: false

    // Failed attempts add a growing delay before the next try, so a mashed
    // keyboard can't spin PAM. Capped so a genuine typo isn't a minute-long
    // lockout: 0s, 1s, 2s, 4s, 8s, 8s…
    readonly property int backoffMs: attempts === 0 ? 0 : Math.min(8000, 500 * Math.pow(2, attempts))
    property bool throttled: false

    // Session.lock() only flips the bool, so clear the previous lock's failure
    // state here — otherwise a stale "nope (3)" and its backoff would greet
    // you on the next lock.
    onLockedChanged: if (locked) {
        attempts = 0;
        failed = false;
        throttled = false;
        password = "";
    }

    function tryUnlock(pw) {
        if (checking || throttled)
            return;
        password = pw;
        checking = true;
        pam.start();
    }

    Timer {
        id: backoff
        interval: root.backoffMs
        onTriggered: root.throttled = false
    }

    // Caps-lock state. Neither QML nor quickshell 0.3.0 exposes the keyboard
    // modifier state, so read the keyboard LEDs — but the input<N> numbers
    // shuffle across reboots, so the path has to be globbed, which FileView
    // can't do. One shell loop streams changes for the duration of the lock
    // and dies with it (`running` follows `locked`); any LED lit counts, since
    // the compositor mirrors caps to every attached keyboard.
    property bool capsLock: false

    Process {
        running: root.locked
        command: ["sh", "-c",
            "while :; do grep -qs 1 /sys/class/leds/*capslock/brightness && echo 1 || echo 0; sleep 0.3; done"]
        stdout: SplitParser {
            onRead: line => root.capsLock = line.trim() === "1"
        }
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
                root.attempts = 0;
                root.failed = false;
                Session.locked = false;
            } else {
                root.attempts += 1;
                root.failed = true;
                root.throttled = true;
                backoff.restart();
            }
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            id: surface

            color: Theme.crust

            Image {
                id: bg
                anchors.fill: parent
                // same source as the desktop behind it (per output)
                source: Wallpapers.forOutput(surface.screen?.name ?? "")
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
                        // keep focus during the backoff so typing resumes the
                        // moment it lifts; tryUnlock() is what actually refuses
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
                        text: root.throttled
                            ? "wait " + Math.ceil(root.backoffMs / 1000) + "s (" + root.attempts + ")"
                            : "nope (" + root.attempts + ")"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.italic: true
                        color: Theme.red
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.capsLock
                    text: "󰪛  caps lock"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: Theme.yellow
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
