// The lock screen's card: avatar, name, password field, one status line. The
// surface that has the keyboard draws it at full strength with the accent
// ring; the others fade it back so it's obvious where typing goes.
import QtQuick
import qs.Components
import qs.Services
import qs.Theme

Surface {
    id: card

    required property var lock
    property bool hasKeyboard: true

    elevation: 2
    width: 360
    height: col.implicitHeight + 2 * Theme.spacingXl
    color: Theme.alpha(Theme.base, 0.9)
    borderColor: hasKeyboard ? Theme.alpha(Theme.accent, 0.5) : Theme.outline
    opacity: hasKeyboard ? 1 : 0.55

    Behavior on opacity {
        NumberAnimation { duration: Theme.durationShort }
    }

    Connections {
        target: card.lock
        function onRejected() { field.shake(); }
    }

    Column {
        id: col
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.spacingXl
        }
        spacing: Theme.spacingMd

        // ── avatar ──
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 72
            height: 72
            radius: 36
            color: Theme.accent
            clip: true

            Image {
                anchors.fill: parent
                visible: User.avatarUrl !== ""
                source: User.avatarUrl
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(144, 144)
                layer.enabled: true
                layer.smooth: true
            }

            Text {
                anchors.centerIn: parent
                visible: User.avatarUrl === ""
                text: User.initial
                font.family: Theme.fontFamily
                font.pixelSize: 32
                font.weight: Theme.weightBold
                color: Theme.onAccent
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: User.fullName
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMedium
            font.weight: Theme.weightBold
            color: Theme.textPrimary
        }

        PasswordField {
            id: field
            width: parent.width
            placeholder: "password"
            failed: card.lock.failed
            checking: card.lock.checking
            fieldEnabled: !card.lock.throttled
            focused: card.hasKeyboard
            onAccepted: t => card.lock.tryUnlock(t)
        }

        // ── status / hint ──
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            height: 18
            verticalAlignment: Text.AlignVCenter
            text: card.lock.status !== "" ? card.lock.status : "enter to unlock"
            font.family: Theme.fontFamily
            font.pixelSize: card.lock.status !== "" ? Theme.fontLabel : Theme.fontTiny
            color: card.lock.failed ? Theme.error : Theme.textMuted
            opacity: card.lock.status !== "" || field.text === "" ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.durationShort }
            }
        }
    }
}
