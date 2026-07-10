// Default sink volume via native pipewire — click mutes, right-click opens
// pavucontrol, scroll ±5% (same bindings as the old waybar pulseaudio module,
// minus the wpctl shell-outs).
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Theme

BarText {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int vol: Math.round((sink?.audio?.volume ?? 0) * 100)

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    text: muted ? "󰝟  muted"
        : (vol <= 33 ? "󰕿" : vol <= 66 ? "󰖀" : "󰕾") + "  " + vol + "%"
    color: muted ? Theme.overlay0 : Theme.teal

    onModuleClicked: button => {
        if (button === Qt.LeftButton && sink?.audio)
            sink.audio.muted = !sink.audio.muted;
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
