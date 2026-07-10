// Thin separator grouping right-island modules (waybar border-left).
import QtQuick
import qs.Theme

Rectangle {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: 1
    height: 16
    color: Theme.alpha(Theme.surface0, 0.8)
}
