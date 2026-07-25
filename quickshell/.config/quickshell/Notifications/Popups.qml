pragma ComponentBehavior: Bound
// Popup toasts — top-right of the FOCUSED output on the overlay layer, like the
// old swaync notification window. (These used to be pinned to a hardcoded
// "eDP-1", which is both a connector name in a portable dotfiles repo and a
// guarantee you miss toasts while working on another monitor.)
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services
import qs.Theme

Scope {
    PanelWindow {
        screen: Niri.focusedScreen
        visible: Notifs.popups.length > 0

        anchors {
            top: true
            right: true
        }
        margins {
            top: 6
            right: 10
        }
        // Normal (zone 0): respect the bar's exclusive zone so toasts stack
        // below it — Ignore would overlay the bar itself
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        implicitWidth: 400
        implicitHeight: stack.implicitHeight

        Column {
            id: stack
            width: 400
            spacing: Theme.spacingSm

            // groupList() rebuilds the array on any notification change; keying
            // by the group key keeps existing cards (and their timers) alive
            ScriptModel {
                id: popupModel
                objectProp: "key"
                values: Notifs.popupGroups
            }

            Repeater {
                model: popupModel

                NotificationCard {
                    required property var modelData
                    notif: modelData.latest
                    group: modelData
                    isPopup: true
                    width: parent.width
                }
            }
        }
    }
}
