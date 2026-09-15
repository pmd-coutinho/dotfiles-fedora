// A nerd-font glyph in a fixed optical box. Glyph advances vary wildly (a wifi
// arc is wider than a bell), so without the width floor an icon column jitters
// as the state changes.
import QtQuick
import qs.Theme

Text {
    property string glyph
    property int size: Theme.iconSize

    text: glyph
    font.family: Theme.fontFamily
    font.pixelSize: size
    color: Theme.textSecondary
    width: Math.max(implicitWidth, size)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast }
    }
}
