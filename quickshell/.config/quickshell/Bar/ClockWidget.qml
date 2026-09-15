// Clock: HH:mm. Click opens the calendar menu (Bar/CalendarMenu.qml — a real
// menu you can move the pointer into, unlike the old hover popup that vanished
// the moment you tried to scroll it); middle-click toggles the long format.
import QtQuick
import Quickshell
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    id: root

    property bool alt: false

    active: Bus.calendarMenu?.isOpenFor(root) ?? false
    padX: Theme.spacingMd
    tip: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
    hint: "click: calendar · middle: " + (alt ? "short" : "long") + " format"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.alt
            ? Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
            : Qt.formatDateTime(clock.date, "HH:mm")
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.weightBold
        color: Theme.textPrimary
    }

    onClicked: button => {
        if (button === Qt.LeftButton)
            Bus.calendarMenu?.openFor(root, root.bar.screen);
        else if (button === Qt.MiddleButton)
            alt = !alt;
    }
}
