// One floating pill ("island") — mirrors the old waybar .modules-* CSS:
// alpha(base,.92) fill, surface0 border, 12px radius, 6px inner padding.
import QtQuick
import qs.Theme

Rectangle {
    default property alias content: inner.data

    height: Theme.barHeight
    implicitWidth: inner.implicitWidth + 12
    radius: Theme.islandRadius
    color: Theme.islandBg
    border.color: Theme.islandBorder
    border.width: 1

    Row {
        id: inner
        anchors.centerIn: parent
        height: parent.height
    }
}
