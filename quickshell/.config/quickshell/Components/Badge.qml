// Small accent count pill (unread notifications, connected devices).
import QtQuick
import qs.Theme

Rectangle {
    property int count: 0
    property color fill: Theme.accent
    property color textColor: Theme.onAccent

    visible: count > 0
    height: 14
    width: Math.max(height, label.implicitWidth + 8)
    radius: height / 2   // pill
    color: fill

    Text {
        id: label
        anchors.centerIn: parent
        text: parent.count > 99 ? "99+" : String(parent.count)
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontTiny
        font.weight: Theme.weightBold
        color: parent.textColor
    }
}
