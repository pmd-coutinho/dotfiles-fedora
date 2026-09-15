pragma ComponentBehavior: Bound
// The bar — three floating islands per output: workspaces + window title on
// the left, the clock in the centre, status modules on the right.
//
// Geometry: the window is `barMarginTop + barHeight + barShadowPad` tall with
// no compositor margins — the top inset is drawn inside so it is never counted
// twice (commit 6a4c180 measured that double count), and the pad below the
// pills exists only so their shadow has somewhere to be drawn. The exclusive
// zone stops at the pills' bottom edge; the shadow fades into niri's `gaps`.
// The input mask is the three pills, so the pad strip is click-through.
//
// Layout: the centre island is intrinsic; the side islands clamp their own
// width to the space left of / right of it, and their elastic children (window
// title, media title) shrink. That replaces the old `mediaBudget` loop-in-a-
// binding that stopped a long track name from running into the clock.
import QtQuick
import Quickshell
import Quickshell.Wayland
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
            implicitHeight: Theme.barMarginTop + Theme.barHeight + Theme.barShadowPad
            exclusiveZone: Theme.barMarginTop + Theme.barHeight + Theme.barGapBelow
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "qs-bar"
            color: "transparent"
            mask: Region {
                regions: [
                    Region { item: leftIsland },
                    Region { item: centreIsland },
                    Region { item: rightIsland }
                ]
            }

            // ── shared hover tooltip (one per bar) ──
            property Item tipTarget: null
            function showTip(item) { tipTarget = item; }
            function hideTip(item) { if (tipTarget === item) tipTarget = null; }

            BarTooltip {
                target: panel.tipTarget
            }

            Item {
                id: content

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: Theme.barMarginTop
                    leftMargin: Theme.barMarginSide
                    rightMargin: Theme.barMarginSide
                }
                height: Theme.barHeight

                // ── centre island: clock (intrinsic width, the others yield to it) ──
                Island {
                    id: centreIsland

                    anchors.horizontalCenter: parent.horizontalCenter

                    ClockWidget { bar: panel }
                }

                // ── left island: workspaces + window title ──
                Island {
                    id: leftIsland

                    anchors.left: parent.left
                    width: Math.max(0, Math.min(implicitWidth, centreIsland.x - Theme.spacingMd))

                    Workspaces {
                        bar: panel
                        output: panel.output
                    }
                    WindowTitle {
                        bar: panel
                        output: panel.output
                    }
                }

                // ── right island: status modules ──
                Island {
                    id: rightIsland

                    anchors.right: parent.right
                    width: Math.max(0, Math.min(implicitWidth,
                        content.width - (centreIsland.x + centreIsland.width) - Theme.spacingMd))

                    RecordingWidget { bar: panel }
                    MicWidget { bar: panel }
                    ScreenToolsWidget { bar: panel }
                    MediaWidget { bar: panel }
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
