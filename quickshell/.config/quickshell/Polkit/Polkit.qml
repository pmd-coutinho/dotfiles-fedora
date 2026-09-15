pragma ComponentBehavior: Bound
// PolicyKit authentication agent, in-shell.
//
// Replaces polkit-mate-agent.service: an unthemed GTK dialog from a package
// installed for nothing else, supervised by a user unit that needed its own fix
// to stay up under niri. Only ONE agent can own a session, so
// polkit-mate-agent must be stopped for this to register — `registered` below
// is the thing to check if prompts stop appearing.
//
// Every output is scrimmed while a prompt is up; the card sits on the output
// that had focus. Enter/Esc still work, and there are Cancel / Authenticate
// buttons for the pointer. AuthFlow in quickshell 0.3.1 has no requesting-
// process identity (no pid, no app name) — the action's icon and id are the
// best "who is asking" hint available, so both are shown.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Polkit
import qs.Components
import qs.Services
import qs.Theme

Scope {
    id: root

    readonly property bool registered: agent.isRegistered
    readonly property var flow: agent.flow

    property bool mounted: false
    property bool shown: false
    property var targetScreen: null
    property bool submitted: false
    property bool succeeded: false
    // a response went out and polkit hasn't asked for the next one yet
    readonly property bool busy: submitted && !(flow?.isResponseRequired ?? false) && !(flow?.isCompleted ?? true)

    signal rejected()

    PolkitAgent {
        id: agent
    }

    onRegisteredChanged: {
        if (!registered)
            console.warn("polkit: agent not registered — is polkit-mate-agent still running?");
    }

    onFlowChanged: {
        if (flow) {
            submitted = false;
            succeeded = false;
            targetScreen = Niri.focusedScreen;
            unmount.stop();
            mounted = true;
            arm.restart();
        } else {
            arm.stop();
            shown = false;
            unmount.restart();
        }
    }

    Connections {
        target: root.flow
        function onIsResponseRequiredChanged() {
            if (root.flow.isResponseRequired)
                root.submitted = false;   // next prompt (or a retry)
        }
        function onAuthenticationFailed() {
            root.submitted = false;
            root.rejected();
        }
        function onSupplementaryIsErrorChanged() {
            if (root.flow.supplementaryIsError)
                root.rejected();
        }
        function onAuthenticationSucceeded() {
            root.succeeded = true;
        }
    }

    function submit(text) {
        if (!flow || text === "")
            return;
        submitted = true;
        flow.submit(text);
    }

    Timer {
        id: arm
        interval: 16
        onTriggered: root.shown = true
    }

    Timer {
        id: unmount
        interval: Theme.durationMedium + 50
        onTriggered: if (!root.flow) root.mounted = false
    }

    LazyLoader {
        active: root.mounted

        Variants {
            model: Quickshell.screens

            PanelWindow {
                id: win

                required property ShellScreen modelData
                readonly property bool primary: modelData === root.targetScreen

                screen: modelData
                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-polkit"
                // keyboard has to be ours: the user is about to type a password
                WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    color: Theme.crust
                    opacity: root.shown ? 0.6 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.durationMedium }
                    }
                }

                Loader {
                    anchors.fill: parent
                    active: win.primary

                    sourceComponent: FocusScope {
                        focus: true

                        Keys.onEscapePressed: root.flow?.cancelAuthenticationRequest()

                        Surface {
                            id: card

                            anchors.centerIn: parent
                            elevation: 2
                            width: 460
                            height: content.implicitHeight + 2 * Theme.spacingXl
                            borderColor: root.succeeded ? Theme.success : Theme.outline
                            borderWidth: root.succeeded ? 2 : 1
                            scale: root.shown ? 1 : 0.96
                            opacity: root.shown ? 1 : 0

                            Behavior on scale {
                                NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easeStandard }
                            }
                            Behavior on opacity {
                                NumberAnimation { duration: Theme.durationMedium }
                            }

                            ColumnLayout {
                                id: content
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: Theme.spacingXl
                                }
                                spacing: Theme.spacingMd

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingMd

                                    IconImage {
                                        implicitSize: 40
                                        source: Quickshell.iconPath(root.flow?.iconName || "dialog-password", "security-high")
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Authentication required"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontLarge
                                            font.weight: Theme.weightBold
                                            color: Theme.accent
                                        }

                                        // which action is being authorised — useful
                                        // for spotting a prompt you did not expect
                                        Text {
                                            Layout.fillWidth: true
                                            visible: (root.flow?.actionId ?? "") !== ""
                                            elide: Text.ElideMiddle
                                            text: root.flow?.actionId ?? ""
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontTiny
                                            color: Theme.textHint
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: root.flow?.message ?? ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    color: Theme.textPrimary
                                }

                                PasswordField {
                                    id: field
                                    Layout.fillWidth: true
                                    visible: root.flow?.isResponseRequired ?? false
                                    // polkit tells us whether this response is a
                                    // secret (password) or plain (e.g. a token id)
                                    secret: !(root.flow?.responseVisible ?? false)
                                    placeholder: root.flow?.inputPrompt || "password…"
                                    failed: root.flow?.supplementaryIsError ?? false
                                    checking: root.busy
                                    onAccepted: t => root.submit(t)
                                    onEscaped: root.flow?.cancelAuthenticationRequest()
                                    onVisibleChanged: if (visible) takeFocus()
                                    Component.onCompleted: takeFocus()

                                    Connections {
                                        target: root
                                        function onRejected() { field.shake(); }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: (root.flow?.supplementaryMessage ?? "") !== ""
                                    wrapMode: Text.WordWrap
                                    text: root.flow?.supplementaryMessage ?? ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontLabel
                                    color: (root.flow?.supplementaryIsError ?? false) ? Theme.error : Theme.textSecondary
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Theme.spacingXs
                                    spacing: Theme.spacingSm

                                    Text {
                                        Layout.fillWidth: true
                                        text: "enter · esc"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontTiny
                                        color: Theme.textMuted
                                    }

                                    Button {
                                        text: "Cancel"
                                        onClicked: root.flow?.cancelAuthenticationRequest()
                                    }

                                    Button {
                                        kind: "primary"
                                        text: "Authenticate"
                                        enabled: field.text !== "" && !root.busy
                                        onClicked: {
                                            const t = field.text;
                                            field.clear();
                                            root.submit(t);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
