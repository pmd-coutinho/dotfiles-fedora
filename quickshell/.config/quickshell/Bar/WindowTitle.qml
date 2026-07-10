// Focused-window title of this output's active workspace (waybar niri/window
// with separate-outputs), truncated at 45 chars like the old max-length.
import QtQuick
import qs.Services
import qs.Theme

Text {
    property string output

    readonly property string title: Niri.activeWindowTitleOn(output)

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    visible: title !== ""
    leftPadding: 12
    rightPadding: 12
    text: title.length > 45 ? title.slice(0, 44) + "…" : title
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Font.Medium
    font.italic: true
    color: Theme.subtext0
    verticalAlignment: Text.AlignVCenter
}
