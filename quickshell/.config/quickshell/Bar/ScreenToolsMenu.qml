// Screen tools in one place: screenshot, record, OCR, colour pick, QR scan.
//
// Every entry runs the same script as its keybind, so this is a discoverable
// front-end rather than a second implementation — the bindings are shown on each
// row precisely so the menu teaches them and then stops being needed.
import QtQuick
import Quickshell
import qs.Components
import qs.Services
import qs.Theme

MenuWindow {
    id: menu

    boxWidth: Theme.menuWidthWide

    // close first: several of these open a slurp overlay, and the scrim would
    // otherwise be in the way of the region select
    function run(cmd) {
        menu.close();
        Quickshell.execDetached(cmd);
    }

    SectionHeader { text: "capture" }

    MenuRow {
        glyph: Icons.screenshot
        label: "Screenshot — region or monitor"
        detail: "Print"
        onTriggered: menu.run(["screenshot-region"])
    }

    MenuRow {
        glyph: Icons.screenshotFull
        label: "Screenshot — whole desktop"
        detail: "Shift+Print"
        onTriggered: menu.run(["sh", "-c", "grim - | satty -f -"])
    }

    SectionHeader { text: "record" }

    MenuRow {
        glyph: Recorder.active ? Icons.stop : Icons.record
        glyphColor: Recorder.active ? Theme.error : Theme.accent
        label: Recorder.active ? "Stop recording" : "Record — region or monitor"
        detail: "Mod+Shift+Print"
        onTriggered: menu.run(["screen-record"])
    }

    MenuRow {
        // starting a second recording would just stop the first (the script is
        // a toggle), so hide this while one is running
        visible: !Recorder.active
        glyph: Icons.record
        label: "Record — with audio"
        detail: "Mod+Alt+Print"
        onTriggered: menu.run(["screen-record", "-a"])
    }

    SectionHeader { text: "extract" }

    MenuRow {
        glyph: Icons.ocr
        label: "OCR text → clipboard"
        detail: "Mod+Shift+T"
        onTriggered: menu.run(["screen-ocr"])
    }

    MenuRow {
        glyph: Icons.colorPick
        label: "Pick a colour → hex"
        detail: "Mod+Shift+C"
        onTriggered: menu.run(["color-pick"])
    }

    MenuRow {
        glyph: Icons.qr
        label: "Scan QR / barcode"
        detail: "Mod+Shift+Q"
        onTriggered: menu.run(["qr-scan"])
    }
}
