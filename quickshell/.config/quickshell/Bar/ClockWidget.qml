pragma ComponentBehavior: Bound
// Clock: HH:mm, click toggles the long format; hovering opens the calendar
// popup (the old waybar Pango-calendar tooltip, scroll to change month).
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Theme

BarText {
    id: root

    property bool alt: false

    text: alt
        ? Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
        : Qt.formatDateTime(clock.date, "HH:mm")
    color: Theme.lavender
    font.weight: Font.Bold
    leftPadding: 16
    rightPadding: 16

    onModuleClicked: button => {
        if (button === Qt.LeftButton)
            alt = !alt;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    HoverHandler {
        id: hover
    }

    PopupWindow {
        id: calWin

        visible: hover.hovered
        color: "transparent"
        implicitWidth: calBox.implicitWidth
        implicitHeight: calBox.implicitHeight

        onVisibleChanged: {
            if (visible) {
                grid.month = clock.date.getMonth();
                grid.year = clock.date.getFullYear();
            }
        }

        anchor {
            window: root.bar
            rect.x: root.mapToItem(null, root.width / 2, 0).x - calWin.implicitWidth / 2
            rect.y: Theme.barHeight + Theme.barMarginTop
        }

        Rectangle {
            id: calBox
            implicitWidth: content.implicitWidth + 24
            implicitHeight: content.implicitHeight + 24
            color: Theme.mantle
            border.color: Theme.surface0
            border.width: 1
            radius: Theme.islandRadius

            // scroll changes month (waybar calendar on-scroll)
            WheelHandler {
                onWheel: event => {
                    const d = new Date(grid.year, grid.month + (event.angleDelta.y < 0 ? 1 : -1), 1);
                    grid.month = d.getMonth();
                    grid.year = d.getFullYear();
                }
            }

            Column {
                id: content
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(new Date(grid.year, grid.month, 1), "MMMM yyyy")
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.Bold
                    color: Theme.mauve
                }

                DayOfWeekRow {
                    width: grid.width

                    delegate: Text {
                        required property var model
                        text: model.shortName
                        horizontalAlignment: Text.AlignHCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        font.weight: Font.Bold
                        color: Theme.yellow
                    }
                }

                MonthGrid {
                    id: grid
                    width: 7 * 30
                    height: 6 * 24

                    delegate: Text {
                        required property var model
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: model.day
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        font.weight: model.today ? Font.Bold : Font.Medium
                        font.underline: model.today
                        color: model.today ? Theme.red
                             : model.month === grid.month ? Theme.text
                             : Theme.overlay0
                    }
                }
            }
        }
    }
}
