// Default sink volume via native pipewire — click mutes, scroll ±5%,
// right-click opens the control center's audio page (devices + profiles).
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real vol: sink?.audio?.volume ?? 0

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    // the short name where pipewire has one ("WH-1000XM4"), the description
    // otherwise — the tooltip is a glance, not a device inventory
    readonly property string sinkLabel: !sink ? "no output"
        : sink.nickname !== "" ? sink.nickname
        : sink.description !== "" ? sink.description
        : sink.name

    tip: (muted ? "muted" : Math.round(vol * 100) + "%") + " · " + sinkLabel
    hint: "click: mute · scroll: volume · right: devices"

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: Icons.volume(root.vol, root.muted)
        color: root.muted ? Theme.textMuted : Theme.teal
    }

    Ring {
        anchors.verticalCenter: parent.verticalCenter
        value: root.muted ? 0 : root.vol
        color: Theme.teal
    }

    onClicked: button => {
        if (button === Qt.LeftButton && sink?.audio)
            sink.audio.muted = !sink.audio.muted;
        else if (button === Qt.RightButton) {
            if (Bus.controlCenter)
                Bus.controlCenter.open("audio");
            else
                Quickshell.execDetached(["pavucontrol"]);
        }
    }

    onScrolled: delta => {
        if (!sink?.audio)
            return;
        const step = delta > 0 ? 0.05 : -0.05;
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + step));
    }
}
