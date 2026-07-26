pragma ComponentBehavior: Bound
// Popup toasts — top-right, on the overlay layer, like the old swaync window.
//
// Pinned to ONE output on purpose: toasts that follow focus move around while
// you work, and glancing at a fixed corner is easier than hunting for them.
// Falls back to the focused output when that monitor isn't connected, so
// undocking doesn't silently swallow every notification — which is what a bare
// hardcoded connector name would do.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services
import qs.Theme

Scope {
    id: root

    // connector name; `niri msg outputs` lists them
    readonly property string preferredOutput: "eDP-1"

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === root.preferredOutput)
            ?? Niri.focusedScreen
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
