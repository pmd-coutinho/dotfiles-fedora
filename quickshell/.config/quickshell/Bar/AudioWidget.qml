// Default sink volume via native pipewire — click mutes, middle-click opens the
// output/input picker, right-click opens pavucontrol, scroll ±5% (the waybar
// pulseaudio bindings, minus the wpctl shell-outs).
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Services
import qs.Theme

BarText {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int vol: Math.round((sink?.audio?.volume ?? 0) * 100)

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    text: muted ? Icons.volume(0, true) + "  muted"
        : Icons.volume(vol / 100, false) + "  " + vol + "%"
    color: muted ? Theme.overlay0 : Theme.teal

    // Bus.audioMenu is assigned in shell.qml's Component.onCompleted, so it can
    // be null on the first evaluation — fall back to the raw node description
    // rather than rendering the string "undefined".
    readonly property string sinkLabel: sink
        ? (Bus.audioMenu?.label(sink) ?? sink.description ?? sink.name ?? "output")
        : "no output"

    tip: (sink ? Icons.volume(vol / 100, muted) + "  " + sinkLabel : sinkLabel)
        + "\nL: mute · M: pick device · R: pavucontrol · scroll: volume"

    onModuleClicked: button => {
        if (button === Qt.LeftButton && sink?.audio)
            sink.audio.muted = !sink.audio.muted;
        else if (button === Qt.MiddleButton)
            Bus.audioMenu?.openFor(root, root.bar.screen);
        else if (button === Qt.RightButton)
            Quickshell.execDetached(["pavucontrol"]);
    }

    onModuleScrolled: delta => {
        if (!sink?.audio)
            return;
        const step = delta > 0 ? 0.05 : -0.05;
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + step));
    }
}
