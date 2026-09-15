// Clock: HH:mm. Click opens the calendar menu (Bar/CalendarMenu.qml — a real
// menu you can move the pointer into, unlike the old hover popup that vanished
// the moment you tried to scroll it); the tooltip carries the full date.
import QtQuick
import Quickshell
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    id: root

    active: Bus.calendarMenu?.isOpenFor(root) ?? false
    padX: Theme.spacingMd
    tip: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
    hint: "click: calendar"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, "HH:mm")
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.weightBold
        color: Theme.textPrimary
    }

    onClicked: button => {
        if (button === Qt.LeftButton)
            Bus.calendarMenu?.openFor(root, root.bar.screen);
    }
}
