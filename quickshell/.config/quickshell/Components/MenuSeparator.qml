// Hairline between menu sections.
import QtQuick
import qs.Theme

Item {
    width: parent ? parent.width : 0
    height: 9

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.spacingSm
        width: parent.width - 2 * Theme.spacingSm
        height: 1
        color: Theme.outlineSubtle
    }
}
