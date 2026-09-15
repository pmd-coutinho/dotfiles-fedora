// Output / input devices and card profiles (Bar/AudioDevices.qml); the
// volume module's right-click lands here. Stays open after a pick.
import QtQuick
import Quickshell
import qs.Bar
import qs.Components
import qs.Services
import qs.Theme

Page {
    title: "Audio"

    // card profiles come from pactl, so only pay for them when opening
    Component.onCompleted: AudioCards.refresh()

    AudioDevices {}

    Item { width: 1; height: Theme.spacingSm }

    MenuRow {
        glyph: Icons.settings
        glyphColor: Theme.textMuted
        label: "Advanced (pavucontrol)…"
        sublabel: "per-app volumes, latency"
        onTriggered: Quickshell.execDetached(["pavucontrol"])
    }
}
