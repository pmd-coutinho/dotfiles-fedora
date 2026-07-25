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
                    output: panel.output
                }
                WindowTitle {
                    output: panel.output
                }
            }

            // ── center island: clock ──
            Island {
                id: centerIsland

                anchors.horizontalCenter: parent.horizontalCenter

                ClockWidget {
                    bar: panel
                }
            }

            // ── right island: status modules ──
            Island {
                anchors.right: parent.right

                Row {
                    id: rightRow

                    // The three islands are anchored independently, so nothing
                    // stops this one growing left into the clock. Everything
                    // here is fixed-width except the media title, so give that
                    // whatever is left between the clock and the right edge.
                    // Without this a long track name overlaps the clock on a
                    // 1920-wide output (there's room at 2560, which is why it
                    // only showed up on the FHD screens).
                    readonly property real mediaBudget: {
                        const toClock = (panel.width - centerIsland.width) / 2
                            - Theme.barMarginSide - Theme.spacingMd;
                        let others = 0;
                        let gaps = 0;
                        for (const c of children) {
                            // Must not read ANY property of `media` here: its
                            // width and visibility both derive from this budget,
                            // so touching either is a binding loop (was one).
                            if (c === media || !c.visible)
                                continue;
                            others += c.width;
                            gaps += 1;
                        }
                        return Math.max(0, toClock - others - spacing * gaps);
                    }

                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    spacing: Theme.spacingSm

                    RecordingWidget { bar: panel }
                    MicWidget { bar: panel }
                    MediaWidget {
                        id: media
                        bar: panel
                        maxWidth: rightRow.mediaBudget
                    }
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
                    CaffeineWidget { bar: panel }
                    NightLightWidget { bar: panel }
                    BatteryWidget { bar: panel }
                    Divider {}
                    NotificationWidget { bar: panel }
                }
            }
        }
    }
}
