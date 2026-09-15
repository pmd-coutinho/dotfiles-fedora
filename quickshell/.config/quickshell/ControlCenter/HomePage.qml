// Root page of the drawer: a segmented Controls | Notifications switch over
// the two tabs. Two tabs rather than one long column — on the 1080-logical
// outputs a history list under the controls would be squeezed back into the
// proportions of the old swaync panel.
import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Theme

Item {
    id: page

    property string tab: "controls"
    readonly property string title: tab === "controls" ? "Control center" : "Notifications"

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacingSm

        // ── segmented switch ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 32
            radius: height / 2
            color: Theme.surfaceRaised

            Rectangle {
                id: thumb
                width: parent.width / 2
                height: parent.height
                radius: height / 2
                color: Theme.accent
                x: page.tab === "controls" ? 0 : parent.width / 2

                Behavior on x {
                    NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easeStandard }
                }
            }

            Row {
                anchors.fill: parent

                Repeater {
                    model: [
                        { key: "controls", label: "Controls" },
                        { key: "notifications", label: "Notifications", badge: true }
                    ]

                    Item {
                        id: seg
                        required property var modelData
                        readonly property bool current: page.tab === modelData.key
                        width: parent.width / 2
                        height: parent.height

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXs

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: seg.modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                font.weight: Theme.weightBold
                                color: seg.current ? Theme.onAccent : Theme.textSecondary

                                Behavior on color {
                                    ColorAnimation { duration: Theme.durationShort }
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: (seg.modelData.badge ?? false) && Notifs.unread > 0
                                width: Math.max(16, n.implicitWidth + 8)
                                height: 16
                                radius: height / 2
                                color: seg.current ? Theme.onAccent : Theme.accent

                                Text {
                                    id: n
                                    anchors.centerIn: parent
                                    text: Notifs.unread > 99 ? "99+" : Notifs.unread
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontTiny
                                    font.weight: Theme.weightBold
                                    color: seg.current ? Theme.accent : Theme.onAccent
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.tab = seg.modelData.key
                        }
                    }
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: page.tab === "controls" ? 0 : 1

            ControlsTab {}
            NotificationsTab {
                active: page.tab === "notifications" && Notifs.panelOpen
            }
        }
    }
}
