pragma ComponentBehavior: Bound
// Screen tools in one place: screenshot, record, OCR, colour pick, QR scan.
//
// Every entry runs the same script as its keybind, so this is a discoverable
// front-end rather than a second implementation — the bindings are shown on each
// row precisely so the menu teaches them and then stops being needed.
import QtQuick
import Quickshell
import qs.Services
import qs.Theme

MenuWindow {
    id: menu

    boxWidth: 340

    component ToolRow: Rectangle {
        id: row

        required property string glyph
        required property string label
        required property string bind
        required property var run
        property color glyphColor: Theme.mauve

        width: parent.width
        height: 30
        radius: Theme.radiusSmall
        color: area.containsMouse ? Theme.surface0 : "transparent"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 8
            width: 20
            text: row.glyph
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMedium
            color: row.glyphColor
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 34
            width: parent.width - 34 - bindLabel.width - 16
            elide: Text.ElideRight
            text: row.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: Theme.text
        }

        Text {
            id: bindLabel
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: row.bind
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTiny
            color: Theme.overlay1
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                // close first: several of these open a slurp overlay, and the
                // scrim would otherwise be in the way of the region select
                menu.close();
                row.run();
            }
        }
    }

    component Header: Text {
        leftPadding: 8
        topPadding: 4
        bottomPadding: 2
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.weight: Font.Bold
        color: Theme.mauve
    }

    Header { text: "capture" }

    ToolRow {
        glyph: "󰹑"
        label: "Screenshot — region or monitor"
        bind: "Print"
        run: () => Quickshell.execDetached(["screenshot-region"])
    }

    ToolRow {
        glyph: "󰍹"
        label: "Screenshot — whole desktop"
        bind: "Shift+Print"
        run: () => Quickshell.execDetached(["sh", "-c", "grim - | satty -f -"])
    }

    Header { text: "record" }

    ToolRow {
        glyph: Recorder.active ? "󰓛" : "󰕧"
        glyphColor: Recorder.active ? Theme.red : Theme.mauve
        label: Recorder.active ? "Stop recording" : "Record — region or monitor"
        bind: "Mod+Shift+Print"
        run: () => Quickshell.execDetached(["screen-record"])
    }

    ToolRow {
        // starting a second recording would just stop the first (the script is
        // a toggle), so hide this while one is running
        visible: !Recorder.active
        glyph: "󰕧"
        label: "Record — with audio"
        bind: "Mod+Alt+Print"
        run: () => Quickshell.execDetached(["screen-record", "-a"])
    }

    Header { text: "extract" }

    ToolRow {
        glyph: "󱄽"
        label: "OCR text → clipboard"
        bind: "Mod+Shift+T"
        run: () => Quickshell.execDetached(["screen-ocr"])
    }

    ToolRow {
        glyph: "󰝥"
        label: "Pick a colour → hex"
        bind: "Mod+Shift+C"
        run: () => Quickshell.execDetached(["color-pick"])
    }

    ToolRow {
        glyph: "󰐳"
        label: "Scan QR / barcode"
        bind: "Mod+Shift+Q"
        run: () => Quickshell.execDetached(["qr-scan"])
    }
}
