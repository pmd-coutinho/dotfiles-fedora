// Notification bell — native state from the quickshell notification server.
// Click toggles the panel, right-click toggles do-not-disturb.
import QtQuick
import qs.Services
import qs.Theme

BarText {
    text: Notifs.dnd ? "󰂛" : Notifs.count > 0 ? "󱅫" : "󰂚"
    color: Theme.mauve
    font.pixelSize: Theme.fontSize + 1
    rightPadding: 14

    onModuleClicked: button => {
        if (button === Qt.LeftButton)
            Notifs.panelOpen = !Notifs.panelOpen;
        else if (button === Qt.RightButton)
            Notifs.dnd = !Notifs.dnd;
    }
}
