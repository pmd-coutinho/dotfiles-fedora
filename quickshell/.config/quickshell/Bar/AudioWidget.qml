// Default sink volume via native pipewire — click mutes, scroll ±5%,
// middle-click opens the output/input picker, right-click the audio page of
// the control center.
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

    // Bus.audioMenu is assigned in shell.qml's Component.onCompleted, so it can
    // be null on the first evaluation — fall back to the raw node description
    // rather than rendering the string "undefined".
    readonly property string sinkLabel: sink
        ? (Bus.audioMenu?.label(sink) ?? sink.description ?? sink.name ?? "output")
        : "no output"

    tip: sink ? (muted ? "muted · " : Math.round(vol * 100) + "% · ") + sinkLabel : sinkLabel
    hint: "click: mute · scroll: volume · middle: pick device · right: settings"

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
        else if (button === Qt.MiddleButton)
            Bus.audioMenu?.openFor(root, root.bar.screen);
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
