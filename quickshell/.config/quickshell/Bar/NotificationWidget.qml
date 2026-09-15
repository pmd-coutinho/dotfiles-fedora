// Notification bell with an unread badge. Click opens the notification list,
// right-click toggles do-not-disturb.
import QtQuick
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    active: Notifs.panelOpen
    tip: (Notifs.count === 0 ? "no notifications" : Notifs.count + " notification" + (Notifs.count === 1 ? "" : "s"))
       + (Notifs.dnd ? " · do not disturb" : "")
    hint: "click: notifications · right: do not disturb"

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: Icons.bellIcon(Notifs.dnd, Notifs.count > 0)
        color: Notifs.dnd ? Theme.textMuted : Theme.accent
    }

    // unread, not total: the badge clears once the list has been looked at
    Badge {
        anchors.verticalCenter: parent.verticalCenter
        count: Notifs.dnd ? 0 : Notifs.unread
    }

    onClicked: button => {
        if (button === Qt.LeftButton) {
            if (Bus.controlCenter)
                Bus.controlCenter.open("notifications");
            else
                Notifs.panelOpen = !Notifs.panelOpen;
        } else if (button === Qt.RightButton) {
            Notifs.dnd = !Notifs.dnd;
        }
    }
}
