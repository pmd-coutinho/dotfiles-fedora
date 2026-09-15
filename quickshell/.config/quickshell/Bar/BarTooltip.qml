// The bar's hover tooltip: a title line (what this is / current state) and an
// optional hint line (what the clicks do). Anchored to the hovered item itself,
// so it tracks it and the compositor clamps it to the output's edge — the old
// one computed an x once, went stale, and overhung the right edge on the
// rightmost module.
import QtQuick
import Quickshell
import qs.Components
import qs.Theme

PopupWindow {
    id: tip

    // the hovered BarItem (or anything with `tip` / `hint` string properties)
    property var target: null
    property bool ready: false

    onTargetChanged: {
        ready = false;
        if (target)
            delay.restart();
        else
            delay.stop();
    }

    Timer {
        id: delay
        interval: Theme.durationTooltip
        onTriggered: tip.ready = true
    }

    visible: target !== null && ready && (target.tip ?? "") !== ""
    color: "transparent"
    implicitWidth: box.implicitWidth
    implicitHeight: box.implicitHeight + Theme.shadowOffset2 + Theme.shadowBlur2

    anchor {
        item: tip.target
        rect.x: 0
        rect.y: 0
        rect.width: tip.target?.width ?? 0
        rect.height: tip.target?.height ?? 0
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: Theme.barShadowPad
        adjustment: PopupAdjustment.SlideX
    }

    Surface {
        id: box
        elevation: 2
        radius: Theme.radiusMedium
        color: Theme.surfaceOverlay
        implicitWidth: Math.min(col.implicitWidth, Theme.tooltipMaxWidth) + 2 * Theme.spacingMd
        implicitHeight: col.implicitHeight + 2 * Theme.spacingSm
        width: implicitWidth
        height: implicitHeight

        Column {
            id: col
            anchors.centerIn: parent
            spacing: 2

            Text {
                text: tip.target?.tip ?? ""
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                width: Math.min(implicitWidth, Theme.tooltipMaxWidth)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: Theme.textPrimary
            }

            Text {
                visible: text !== ""
                text: tip.target?.hint ?? ""
                textFormat: Text.PlainText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                color: Theme.textHint
            }
        }
    }
}
