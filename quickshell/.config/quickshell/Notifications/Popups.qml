pragma ComponentBehavior: Bound
// Popup toasts — top-right, on the overlay layer.
//
// Output: Config.mainOutput (the laptop panel), or the connector set with
// `qs ipc call notifs setPopupOutput <name>`; the focused output only when
// neither is connected. Either way the screen is LATCHED while a stack is on
// screen, so a burst doesn't hop monitors mid-read. The window is full-height and click-through outside the
// cards (input mask), so cards can slide out below the stack without the
// window resizing under them.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Components
import qs.Services
import qs.Theme

Scope {
    id: root

    property var latchedScreen: null
    readonly property int pad: 32   // room for the cards' shadow on the left/bottom

    readonly property var visibleGroups: Notifs.popupGroups.slice(0, Config.maxPopups)
    readonly property int hiddenCount: Math.max(0, Notifs.popupGroups.length - Config.maxPopups)

    Connections {
        target: Notifs
        function onPopupsChanged() {
            if (Notifs.popups.length === 0) {
                root.latchedScreen = null;
                linger.restart();   // keep the window mapped through the last slide-out
            } else if (!root.latchedScreen) {
                root.latchedScreen = Quickshell.screens.find(s => s.name === Notifs.popupOutput)
                    ?? Niri.mainScreen;
            }
        }
    }

    Timer {
        id: linger
        interval: Theme.durationMedium + 50
    }

    PanelWindow {
        screen: root.latchedScreen ?? Niri.mainScreen
        visible: Notifs.popups.length > 0 || linger.running

        anchors {
            top: true
            bottom: true
            right: true
        }
        margins.top: Theme.spacingSm
        // Normal (zone 0): respect the bar's exclusive zone so toasts stack
        // below it — Ignore would overlay the bar itself
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-toasts"
        color: "transparent"
        implicitWidth: Theme.toastWidth + root.pad + Theme.barMarginSide
        mask: Region { item: stack }

        Column {
            id: stack
            x: root.pad
            width: Theme.toastWidth
            spacing: Theme.spacingSm

            ListView {
                id: list
                width: parent.width
                height: contentHeight
                spacing: Theme.spacingSm
                interactive: false
                clip: false

                // groupList() rebuilds the array on any notification change;
                // keying by the group key keeps existing cards (and their
                // countdowns) alive
                model: ScriptModel {
                    objectProp: "key"
                    values: root.visibleGroups
                }

                delegate: NotificationCard {
                    required property var modelData
                    entry: modelData.latest
                    group: modelData
                    isPopup: true
                    width: ListView.view.width
                }

                add: Transition {
                    NumberAnimation { property: "x"; from: 48; to: 0; duration: Theme.durationMedium; easing.type: Theme.easeStandard }
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationMedium }
                }
                remove: Transition {
                    NumberAnimation { property: "x"; to: 64; duration: Theme.durationShort; easing.type: Theme.easeExit }
                    NumberAnimation { property: "opacity"; to: 0; duration: Theme.durationShort }
                }
                displaced: Transition {
                    NumberAnimation { property: "y"; duration: Theme.durationMedium; easing.type: Theme.easeStandard }
                }
            }

            // the rest of a burst, one tap from the list
            Surface {
                visible: root.hiddenCount > 0
                anchors.right: parent.right
                elevation: 2
                radius: height / 2
                width: moreLabel.implicitWidth + 2 * Theme.spacingMd
                height: 26

                Text {
                    id: moreLabel
                    anchors.centerIn: parent
                    text: "+" + root.hiddenCount + " more"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Theme.weightMedium
                    color: Theme.textSecondary
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Bus.controlCenter)
                            Bus.controlCenter.open("notifications");
                        else
                            Notifs.panelOpen = true;
                    }
                }
            }
        }
    }
}
