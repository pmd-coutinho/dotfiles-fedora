// Small accent heading above a group of rows ("output", "paired", "Today").
import QtQuick
import qs.Theme

Text {
    width: parent ? parent.width : implicitWidth
    leftPadding: Theme.spacingSm
    topPadding: Theme.spacingXs
    bottomPadding: 2
    elide: Text.ElideRight
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSmall
    font.weight: Theme.weightBold
    color: Theme.accent
}
