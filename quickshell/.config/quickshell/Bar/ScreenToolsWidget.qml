// Entry point for the screen toolkit (screenshot / record / OCR / colour / QR).
// The keybinds do the same things faster; this exists so they're discoverable
// and so the tools are reachable without remembering five chords.
import QtQuick
import qs.Services
import qs.Theme

BarText {
    id: root

    text: "󰹑"
    // turns red while recording, so the menu's entry point doubles as a second
    // "you are still recording" signal next to RecordingWidget
    color: Recorder.active ? Theme.red : Theme.subtext0
    tip: "screen tools — screenshot, record, OCR, colour, QR"

    onModuleClicked: button => {
        if (button === Qt.LeftButton)
            Bus.screenToolsMenu?.openFor(root, root.bar.screen);
    }
}
