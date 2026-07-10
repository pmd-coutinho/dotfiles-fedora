pragma ComponentBehavior: Bound
// System tray (StatusNotifier): left-click activates, middle-click secondary,
// right-click opens the item's native DBus menu.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.Services
import qs.Theme

Row {
    id: root

    property var bar

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    spacing: 10
    leftPadding: 10
    rightPadding: 6
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        Item {
            id: slot

            required property var modelData

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 16
            implicitHeight: 16

            IconImage {
                anchors.fill: parent
                source: slot.modelData.icon
                opacity: slot.modelData.status === Status.Passive ? 0.5 : 1
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton || slot.modelData.onlyMenu) {
                        if (slot.modelData.hasMenu)
                            Bus.trayMenu?.openFor(slot, slot.modelData.menu, root.bar.screen);
                    } else if (mouse.button === Qt.LeftButton) {
                        slot.modelData.activate();
                    } else {
                        slot.modelData.secondaryActivate();
                    }
                }
            }
        }
    }
}
