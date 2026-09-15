// Entry point for the screen toolkit (screenshot / record / OCR / colour / QR).
// The keybinds do the same things faster; this exists so they're discoverable
// and so the tools are reachable without remembering five chords.
import QtQuick
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    id: root

    active: Bus.screenToolsMenu?.isOpenFor(root) ?? false
    tip: "screen tools"
    hint: "screenshot · record · OCR · colour · QR"

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: Icons.screenshot
        // turns red while recording, so the menu's entry point doubles as a
        // second "you are still recording" signal next to RecordingWidget
        color: Recorder.active ? Theme.error : Theme.textSecondary
    }

    onClicked: button => {
        if (button === Qt.LeftButton)
            Bus.screenToolsMenu?.openFor(root, root.bar.screen);
    }
}
