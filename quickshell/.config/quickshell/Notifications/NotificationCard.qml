pragma ComponentBehavior: Bound
// One notification card — used by both the popup toasts and the panel list.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.Services
import qs.Theme

Rectangle {
    id: card

    // The server destroys a notification the moment it closes, so every read
    // below is null-tolerant: bindings get one last evaluation before the
    // delegate holding them is torn down.
    required property var notif
    // popups auto-hide on a timer; panel cards persist
    property bool isPopup: false
    // group of same app+summary notifications this card represents
    property var group: null
    readonly property int count: group?.count ?? 1

    implicitHeight: layout.implicitHeight + 24
    radius: Theme.islandRadius
    color: Theme.alpha(Theme.base, 0.98)
    border.width: 1
    border.color: notif?.urgency === NotificationUrgency.Critical ? Theme.red : Theme.surface0

    MouseArea {
        anchors.fill: parent
        onClicked: Notifs.activate(card.notif, card.group)
    }

    Timer {
        interval: Notifs.timeoutFor(card.notif)
        running: card.isPopup && interval > 0
        onTriggered: card.group ? Notifs.hideGroupPopup(card.group) : Notifs.hidePopup(card.notif)
    }

    Column {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 6

        Row {
            width: parent.width
            spacing: 10

            IconImage {
                id: icon
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter
                visible: source.toString() !== ""
                source: (card.notif?.image ?? "") !== "" ? card.notif.image
                      : (card.notif?.appIcon ?? "") !== "" ? Quickshell.iconPath(card.notif.appIcon, true)
                      : ""
            }

            Column {
                width: parent.width - (icon.visible ? 50 : 0) - 26
                spacing: 2

                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        width: parent.width - (countBadge.visible ? countBadge.width + 6 : 0)
                        text: card.notif?.summary ?? ""
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Bold
                        color: Theme.text
                    }

                    Rectangle {
                        id: countBadge
                        visible: card.count > 1
                        width: countText.implicitWidth + 12
                        height: 18
                        radius: height / 2   // pill
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.mauve

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: card.count
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontTiny
                            font.weight: Font.Bold
                            color: Theme.crust
                        }
                    }
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: card.notif?.body ?? ""
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.subtext0
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
                // app name, plus arrival time in the panel list — a toast is
                // obviously "now", but history without times is hard to read
                Text {
                    readonly property string at: card.isPopup ? "" : Notifs.timeOf(card.notif)
                    readonly property string app: card.notif?.appName ?? ""

                    visible: text !== ""
                    text: app + (at !== "" ? (app !== "" ? " · " : "") + at : "")
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.overlay0
                }
            }

            Text {
                text: "󰅖"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: closeArea.containsMouse ? Theme.red : Theme.overlay0

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    onClicked: card.group ? Notifs.dismissGroup(card.group) : card.notif?.dismiss()
                }
            }
        }

        // action buttons (beyond the implicit default action)
        Row {
            visible: actionRepeater.count > 0
            spacing: 6

            Repeater {
                id: actionRepeater
                model: (card.notif?.actions ?? []).filter(a => a.identifier !== "default")

                Rectangle {
                    id: actionBtn
                    required property var modelData
                    implicitWidth: actionLabel.implicitWidth + 20
                    implicitHeight: 24
                    radius: Theme.radiusMedium
                    color: actionArea.containsMouse ? Theme.surface1 : Theme.surface0

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionBtn.modelData.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        color: Theme.text
                    }
                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            actionBtn.modelData.invoke();
                            Notifs.hidePopup(card.notif);
                        }
                    }
                }
            }
        }
    }
}
