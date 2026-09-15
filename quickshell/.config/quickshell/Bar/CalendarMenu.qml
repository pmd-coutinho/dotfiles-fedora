pragma ComponentBehavior: Bound
// Month calendar under the clock. A real menu (scrim, Esc, animation from
// MenuWindow) rather than the old hover popup, which vanished the moment the
// pointer left the clock — so its scroll-to-change-month never actually worked.
// Scroll or use ‹ › to move months, "today" jumps back.
import QtQuick
import QtQuick.Controls
import qs.Components
import qs.Theme

MenuWindow {
    id: menu

    boxWidth: Theme.menuWidthNarrow

    readonly property date today: new Date()
    property int month: today.getMonth()
    property int year: today.getFullYear()

    function reset() {
        const now = new Date();
        month = now.getMonth();
        year = now.getFullYear();
    }

    function step(delta) {
        const d = new Date(year, month + delta, 1);
        month = d.getMonth();
        year = d.getFullYear();
    }

    onShownChanged: if (shown) reset()

    Item {
        width: parent.width
        height: col.implicitHeight + Theme.spacingSm

        WheelHandler {
            onWheel: event => menu.step(event.angleDelta.y < 0 ? 1 : -1)
        }

        Column {
            id: col
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.spacingXs
            spacing: Theme.spacingXs

            // ── header: ‹ month year › · today ──
            Item {
                width: grid.width
                height: 28

                Button {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    compact: true
                    glyph: Icons.chevronLeft
                    onClicked: menu.step(-1)
                }

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(menu.year, menu.month, 1), "MMMM yyyy")
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.weightBold
                    color: Theme.accent
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingXs

                    Button {
                        compact: true
                        text: "today"
                        visible: menu.month !== menu.today.getMonth() || menu.year !== menu.today.getFullYear()
                        onClicked: menu.reset()
                    }
                    Button {
                        compact: true
                        glyph: Icons.chevronRight
                        onClicked: menu.step(1)
                    }
                }
            }

            DayOfWeekRow {
                width: grid.width

                delegate: Text {
                    required property var model
                    text: model.shortName
                    horizontalAlignment: Text.AlignHCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.weight: Theme.weightBold
                    color: Theme.textHint
                }
            }

            MonthGrid {
                id: grid
                month: menu.month
                year: menu.year
                width: 7 * 32
                height: 6 * 28

                delegate: Item {
                    id: day
                    required property var model

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: height / 2
                        color: day.model.today ? Theme.accent : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: day.model.day
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        font.weight: day.model.today ? Theme.weightBold : Theme.weightMedium
                        color: day.model.today ? Theme.onAccent
                             : day.model.month === grid.month ? Theme.textPrimary
                             : Theme.textMuted
                    }
                }
            }
        }
    }
}
