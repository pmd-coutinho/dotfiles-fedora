pragma ComponentBehavior: Bound
// System tray (StatusNotifier): left-click activates, middle-click secondary,
// right-click opens the item's native DBus menu (drawn by TrayMenu.qml).
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.Components
import qs.Services
import qs.Theme

Row {
    id: root

    property var bar

    spacing: 0
    visible: SystemTray.items.values.length > 0
    Layout.minimumWidth: implicitWidth

    Repeater {
        model: SystemTray.items

        BarItem {
            id: slot

            required property var modelData

            bar: root.bar
            padX: 4
            gap: 0
            active: Bus.trayMenu?.isOpenFor(slot) ?? false
            tip: slot.modelData.tooltipTitle !== "" ? slot.modelData.tooltipTitle
               : slot.modelData.title !== "" ? slot.modelData.title
               : slot.modelData.id
            hint: slot.modelData.hasMenu ? "right: menu" : ""

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: Theme.iconSize
                source: slot.modelData.icon
                opacity: slot.modelData.status === Status.Passive ? Theme.disabledOpacity : 1
            }

            onClicked: button => {
                if (button === Qt.RightButton || slot.modelData.onlyMenu) {
                    if (slot.modelData.hasMenu)
                        Bus.trayMenu?.openMenu(slot, slot.modelData.menu, root.bar.screen);
                } else if (button === Qt.LeftButton) {
                    slot.modelData.activate();
                } else {
                    slot.modelData.secondaryActivate();
                }
            }
        }
    }
}
