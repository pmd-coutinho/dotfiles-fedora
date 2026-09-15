pragma ComponentBehavior: Bound
// Notification history: DND row, per-app groups that expand to their entries,
// Today / Earlier sections, relative times, per-app clear and a Clear-all with
// a six-second Undo.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Components
import qs.Notifications
import qs.Services
import qs.Theme

Item {
    id: tab

    // the tab is on screen and the drawer is open
    property bool active: false
    // group keys the user expanded (session-local)
    property var expanded: ({})

    onActiveChanged: if (active) Notifs.markSeen()

    function toggleExpanded(key) {
        const next = Object.assign({}, expanded);
        if (next[key])
            delete next[key];
        else
            next[key] = true;
        expanded = next;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacingSm

        // ── do not disturb + clear all ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            radius: Theme.radiusMedium
            color: Theme.surfaceRaised

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingMd
                anchors.rightMargin: Theme.spacingSm
                spacing: Theme.spacingSm

                Icon {
                    glyph: Notifs.dnd ? Icons.bellOff : Icons.bell
                    color: Notifs.dnd ? Theme.accent : Theme.textSecondary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Do not disturb"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        font.weight: Theme.weightBold
                        color: Theme.textPrimary
                    }
                    Text {
                        text: Notifs.dndLabel
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        color: Theme.textHint
                    }
                }

                ToggleSwitch {
                    checked: Notifs.dnd
                    onToggled: Notifs.dnd = !Notifs.dnd
                }

                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: dndChev.containsMouse ? Theme.stateHover : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        glyph: Icons.chevronRight
                        size: Theme.iconSizeSm
                        color: Theme.textMuted
                    }
                    MouseArea {
                        id: dndChev
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Bus.controlCenter?.push("dnd")
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: Notifs.count === 0 ? "" : Notifs.count + " notification" + (Notifs.count === 1 ? "" : "s")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                color: Theme.textHint
            }

            Button {
                visible: Notifs.count > 0
                compact: true
                glyph: Icons.trash
                text: "Clear all"
                onClicked: Notifs.clearAll()
            }
        }

        // ── the list ──
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.spacingSm
            boundsBehavior: Flickable.StopAtBounds

            model: ScriptModel {
                objectProp: "key"
                values: Notifs.historyApps
            }

            section.property: "section"
            section.criteria: ViewSection.FullString
            section.delegate: SectionHeader {
                required property string section
                width: list.width
                text: section
            }

            // empty state
            Column {
                anchors.centerIn: parent
                visible: Notifs.count === 0
                spacing: Theme.spacingSm

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    glyph: Icons.bell
                    size: Theme.iconSizeXl
                    color: Theme.textMuted
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No notifications"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.textMuted
                }
            }

            delegate: Rectangle {
                id: groupCard

                required property var modelData
                readonly property bool open: tab.expanded[modelData.key] === true
                readonly property string themedIcon: modelData.appIcon !== "" ? Quickshell.iconPath(modelData.appIcon, true) : ""

                width: ListView.view.width
                implicitHeight: groupCol.implicitHeight
                radius: Theme.radiusLarge
                color: Theme.surfaceRaised

                Column {
                    id: groupCol
                    width: parent.width
                    spacing: Theme.spacingXs

                    // ── app header ──
                    Item {
                        width: parent.width
                        height: 36

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingMd
                            anchors.rightMargin: Theme.spacingXs
                            spacing: Theme.spacingSm

                            IconImage {
                                visible: groupCard.themedIcon !== ""
                                implicitSize: Theme.iconSize
                                source: groupCard.themedIcon
                            }

                            Text {
                                Layout.fillWidth: true
                                text: groupCard.modelData.appName || "notification"
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                font.weight: Theme.weightBold
                                color: Theme.textSecondary
                            }

                            Badge {
                                count: groupCard.modelData.count > 1 ? groupCard.modelData.count : 0
                                fill: Theme.surface2
                                textColor: Theme.textPrimary
                            }

                            Rectangle {
                                implicitWidth: Theme.hitMin
                                implicitHeight: Theme.hitMin
                                radius: height / 2
                                color: clearArea.containsMouse ? Theme.alpha(Theme.error, 0.18) : "transparent"

                                Icon {
                                    anchors.centerIn: parent
                                    glyph: Icons.close
                                    size: Theme.iconSizeSm
                                    color: clearArea.containsMouse ? Theme.error : Theme.textMuted
                                }
                                MouseArea {
                                    id: clearArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifs.clearApp(groupCard.modelData.appKey)
                                }
                            }

                            Rectangle {
                                visible: groupCard.modelData.count > 1
                                implicitWidth: Theme.hitMin
                                implicitHeight: Theme.hitMin
                                radius: height / 2
                                color: expandArea.containsMouse ? Theme.stateHover : "transparent"

                                Icon {
                                    anchors.centerIn: parent
                                    glyph: Icons.chevronDown
                                    size: Theme.iconSizeSm
                                    color: Theme.textMuted
                                    rotation: groupCard.open ? 180 : 0

                                    Behavior on rotation {
                                        NumberAnimation { duration: Theme.durationShort }
                                    }
                                }
                                MouseArea {
                                    id: expandArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: tab.toggleExpanded(groupCard.modelData.key)
                                }
                            }
                        }
                    }

                    // ── entries: the latest, or all when expanded ──
                    Repeater {
                        model: ScriptModel {
                            objectProp: "uid"
                            values: groupCard.open ? groupCard.modelData.entries : [groupCard.modelData.latest]
                        }

                        NotificationCard {
                            required property var modelData
                            entry: modelData
                            group: groupCard.modelData
                            compact: true
                            elevation: 0
                            color: "transparent"
                            borderColor: "transparent"
                            width: groupCard.width
                        }
                    }

                    Item { width: 1; height: Theme.spacingXs }
                }
            }
        }

        // ── undo snackbar ──
        Rectangle {
            Layout.fillWidth: true
            visible: Notifs.trashCount > 0
            implicitHeight: 40
            radius: Theme.radiusMedium
            color: Theme.surface1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingMd
                anchors.rightMargin: Theme.spacingSm

                Text {
                    Layout.fillWidth: true
                    text: "Cleared " + Notifs.trashCount
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.textPrimary
                }

                Button {
                    compact: true
                    kind: "primary"
                    glyph: Icons.undo
                    text: "Undo"
                    onClicked: Notifs.undoClear()
                }
            }
        }
    }
}
