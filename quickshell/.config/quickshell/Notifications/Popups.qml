pragma ComponentBehavior: Bound
// Popup toasts — pinned to the laptop panel (eDP-1) top-right on the overlay
// layer, like the old swaync notification window.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services
import qs.Theme

Scope {
    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === "eDP-1") ?? Quickshell.screens[0]
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
            spacing: 8

            Repeater {
                model: Notifs.popupGroups

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
