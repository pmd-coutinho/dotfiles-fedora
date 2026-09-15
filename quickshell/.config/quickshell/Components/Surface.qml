// Rounded surface with tokenised fill/border and a cheap shadow — the one piece
// of chrome every island, menu, card, drawer and dialog shares.
//
// The shadow is RectangularShadow (Qt ≥ 6.9): a single SDF-shaded quad with no
// offscreen layer, so nine islands across three 144 Hz bars cost nine quads.
// MultiEffect.shadowEnabled and Qt5Compat DropShadow both need `layer.enabled`
// on the source — an FBO per island re-rendered on every clock tick — which is
// why they are not used here. `cached` rasterises the shadow once per size.
//
// Size it yourself (or bind implicitWidth/Height to your content): it does not
// auto-size, so it can host layouts that fill it.
import QtQuick
import QtQuick.Effects
import qs.Theme

Item {
    id: root

    property int elevation: 1                   // 0 flat, 1 bar island, 2 popup/menu/card
    property real radius: Theme.radiusLarge
    property color color: Theme.surface
    property color borderColor: Theme.outline
    property int borderWidth: 1
    property int padding: 0
    default property alias content: inner.data
    readonly property alias background: bg

    RectangularShadow {
        anchors.fill: bg
        visible: root.elevation > 0
        radius: bg.radius
        color: Theme.shadowColor
        blur: root.elevation >= 2 ? Theme.shadowBlur2 : Theme.shadowBlur1
        spread: 0
        offset: Qt.vector2d(0, root.elevation >= 2 ? Theme.shadowOffset2 : Theme.shadowOffset1)
        cached: true
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.radius
        color: root.color
        border.width: root.borderWidth
        border.color: root.borderColor
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
