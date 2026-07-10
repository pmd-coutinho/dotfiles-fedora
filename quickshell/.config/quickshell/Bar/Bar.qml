pragma ComponentBehavior: Bound
// The bar — Catppuccin Mocha "floating islands", one per output, 1:1 port of
// the old waybar look (30px strip, 6/10px margins, three pill groups).
import QtQuick
import Quickshell
import qs.Theme

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property ShellScreen modelData
            readonly property string output: modelData.name

            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            margins {
                top: Theme.barMarginTop
                left: Theme.barMarginSide
                right: Theme.barMarginSide
            }
            implicitHeight: Theme.barHeight
            // reserve the 6px below the bar too (waybar margin-bottom)
            exclusiveZone: Theme.barHeight + Theme.barMarginTop * 2
            color: "transparent"

            // ── shared hover tooltip (one per bar) ──
            property Item tipTarget: null
            function showTip(item) { tipTarget = item; }
            function hideTip(item) { if (tipTarget === item) tipTarget = null; }

            // ── shared tray context menu (one per bar) ──
            property var trayMenu: trayMenuWin

            TrayMenu {
                id: trayMenuWin
                bar: panel
            }

            PopupWindow {
                id: tipWin
                visible: panel.tipTarget !== null && (panel.tipTarget.tip ?? "") !== ""
                color: "transparent"
                implicitWidth: tipText.implicitWidth + 24
                implicitHeight: tipText.implicitHeight + 16
                anchor {
                    window: panel
                    rect.x: panel.tipTarget
                        ? panel.tipTarget.mapToItem(null, panel.tipTarget.width / 2, 0).x - tipWin.implicitWidth / 2
                        : 0
                    rect.y: Theme.barHeight + Theme.barMarginTop
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.mantle
                    border.color: Theme.surface0
                    border.width: 1
                    radius: Theme.islandRadius

                    Text {
                        id: tipText
                        anchors.centerIn: parent
                        text: panel.tipTarget?.tip ?? ""
                        textFormat: Text.PlainText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        color: Theme.text
                    }
                }
            }

            // ── left island: workspaces + window title ──
            Island {
                anchors.left: parent.left

                Workspaces {
                    bar: panel
                    output: panel.output
                }
                WindowTitle {
                    output: panel.output
                }
            }

            // ── center island: clock ──
            Island {
                anchors.horizontalCenter: parent.horizontalCenter

                ClockWidget {
                    bar: panel
                }
            }

            // ── right island: status modules ──
            Island {
                anchors.right: parent.right

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    spacing: 8

                    TrayWidget { bar: panel }
                    Divider {}
                    CpuWidget { bar: panel }
                    MemoryWidget { bar: panel }
                    Divider {}
                    AudioWidget { bar: panel }
                    BluetoothWidget { bar: panel }
                    NetworkWidget { bar: panel }
                    Divider {}
                    PowerProfileWidget { bar: panel }
                    NightLightWidget { bar: panel }
                    BatteryWidget { bar: panel }
                    Divider {}
                    NotificationWidget { bar: panel }
                }
            }
        }
    }
}
