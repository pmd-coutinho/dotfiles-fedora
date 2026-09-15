// Password pill shared by the lock screen and the polkit dialog: placeholder,
// status line, caps-lock chip, a shake + red flash on rejection and animated
// dots while the answer is being checked. The owner drives `failed`,
// `checking` and `statusText`; the field only reports `accepted(text)`.
import QtQuick
import qs.Services
import qs.Theme

Item {
    id: root

    property string placeholder: "password…"
    property string statusText: ""         // shown instead of the placeholder when set
    property bool failed: false
    property bool checking: false
    property bool secret: true             // echo dots (false for a plain polkit prompt)
    property bool fieldEnabled: true       // not `enabled`: that would shadow Item's
    property bool showCaps: true
    property bool focused: true            // draw the accent ring
    readonly property alias text: input.text
    readonly property alias inputItem: input

    signal accepted(string text)
    signal escaped()

    function clear() { input.text = ""; }
    function takeFocus() { input.forceActiveFocus(); }
    function shake() { shakeAnim.restart(); flashAnim.restart(); }

    implicitHeight: Theme.fieldHeight
    implicitWidth: 300

    Item {
        id: pillHolder
        anchors.fill: parent

        Rectangle {
            id: pill
            anchors.fill: parent
            radius: height / 2   // pill
            color: Theme.surfaceRaised
            border.width: 2
            border.color: !root.focused ? Theme.outline
                        : root.failed ? Theme.error
                        : root.checking ? Theme.success
                        : Theme.accent

            Behavior on border.color {
                ColorAnimation { duration: Theme.durationShort }
            }

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingLg
                anchors.rightMargin: capsChip.visible ? capsChip.width + Theme.spacingLg : Theme.spacingLg
                focus: true
                enabled: root.fieldEnabled && !root.checking
                echoMode: root.secret ? TextInput.Password : TextInput.Normal
                passwordCharacter: "•"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMedium
                color: Theme.textPrimary
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                selectByMouse: false

                onTextChanged: if (text !== "") root.failed = false
                onAccepted: {
                    if (text === "")
                        return;
                    const t = text;
                    text = "";
                    root.accepted(t);
                }
                Keys.onEscapePressed: {
                    if (text !== "")
                        text = "";
                    else
                        root.escaped();
                }
                // the LED changes a few ms after the key event (Services/Keyboard.qml)
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_CapsLock)
                        Keyboard.refreshSoon();
                }
            }

            // placeholder / status, only while the field is empty
            Text {
                anchors.centerIn: parent
                visible: input.text === "" && !root.checking
                text: root.statusText !== "" ? root.statusText : root.placeholder
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMedium
                font.italic: root.statusText === ""
                color: root.failed ? Theme.error : Theme.textMuted
            }

            // three breathing dots while the answer is being verified
            Row {
                anchors.centerIn: parent
                visible: root.checking
                spacing: 6

                Repeater {
                    model: 3

                    Rectangle {
                        id: dot
                        required property int index
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.success
                        opacity: 0.3

                        SequentialAnimation on opacity {
                            running: root.checking
                            loops: Animation.Infinite
                            PauseAnimation { duration: dot.index * 120 }
                            NumberAnimation { to: 1; duration: 260 }
                            NumberAnimation { to: 0.3; duration: 260 }
                            PauseAnimation { duration: (2 - dot.index) * 120 }
                        }
                    }
                }
            }

            Rectangle {
                id: capsChip
                visible: root.showCaps && Keyboard.capsLock
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: capsRow.implicitWidth + 12
                height: 22
                radius: height / 2
                color: Theme.alpha(Theme.warning, 0.18)

                Row {
                    id: capsRow
                    anchors.centerIn: parent
                    spacing: 4

                    Icon { glyph: Icons.capsLock; size: Theme.iconSizeSm; color: Theme.warning }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "caps"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTiny
                        color: Theme.warning
                    }
                }
            }

            // red wash that fades out after a rejection
            Rectangle {
                id: flash
                anchors.fill: parent
                radius: parent.radius
                color: Theme.error
                opacity: 0
            }
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: pill; property: "x"; from: 0; to: -10; duration: 40 }
        NumberAnimation { target: pill; property: "x"; to: 10; duration: 70 }
        NumberAnimation { target: pill; property: "x"; to: -6; duration: 60 }
        NumberAnimation { target: pill; property: "x"; to: 4; duration: 50 }
        NumberAnimation { target: pill; property: "x"; to: 0; duration: 50; easing.type: Easing.OutQuad }
    }

    SequentialAnimation {
        id: flashAnim
        NumberAnimation { target: flash; property: "opacity"; to: 0.35; duration: 60 }
        NumberAnimation { target: flash; property: "opacity"; to: 0; duration: 320 }
    }
}
