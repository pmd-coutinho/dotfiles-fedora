pragma ComponentBehavior: Bound
// Volume / mic / brightness OSD — a capability the old stack never had:
// media keys used to change values silently. Reacts to native pipewire
// state and the sysfs backlight, shows on the focused output, hides after
// 1.5s. Keybinds keep calling wpctl/brightnessctl unchanged.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.Services
import qs.Theme

Scope {
    id: root

    property string kind: "volume"   // volume | mic | brightness
    property real value: 0           // 0..1
    property bool muted: false
    property bool shown: false
    // suppress the initial property-change flurry while services connect
    property bool armed: false

    function show(kind, value, muted) {
        if (!armed)
            return;
        root.kind = kind;
        root.value = value;
        root.muted = muted;
        root.shown = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shown = false
    }

    Timer {
        interval: 2000
        running: true
        onTriggered: root.armed = true
    }

    // ── audio (native pipewire signals) ──
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [root.sink, root.source].filter(Boolean)
    }

    // The `?.` inside the handlers matters: `target` is re-evaluated when the
    // default sink changes, and a switch landing between signal emission and
    // handler invocation would otherwise be a hard null deref.
    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() {
            root.showAudio("volume", root.sink?.audio);
        }
        function onMutedChanged() {
            root.showAudio("volume", root.sink?.audio);
        }
    }

    Connections {
        target: root.source?.audio ?? null
        // mic volume used to have no handler at all, so turning the mic up or
        // down showed nothing while the speaker equivalent did
        function onVolumeChanged() {
            root.showAudio("mic", root.source?.audio);
        }
        function onMutedChanged() {
            root.showAudio("mic", root.source?.audio);
        }
    }

    function showAudio(kind, audio) {
        if (!audio)
            return;
        show(kind, audio.volume, audio.muted);
    }

    // ── brightness (sysfs watch) ──
    // The backlight device was hardcoded to intel_backlight, which silently
    // stops working the moment the panel is driven by something else
    // (amdgpu_bl0, nv_backlight...). Discover it once at startup instead.
    property string backlightDir: ""

    Process {
        running: true
        command: ["sh", "-c", "ls -d /sys/class/backlight/*/ 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const dir = text.trim().replace(/\/$/, "");
                if (dir !== "")
                    root.backlightDir = dir;
            }
        }
    }

    FileView {
        id: maxBrightness
        // no blockLoading: the old code did a synchronous read of a path that
        // may not exist at all (a desktop has no backlight)
        path: root.backlightDir === "" ? "" : root.backlightDir + "/max_brightness"
    }

    FileView {
        id: brightness
        path: root.backlightDir === "" ? "" : root.backlightDir + "/brightness"
        watchChanges: true
        onFileChanged: {
            reload();
            const max = Number(maxBrightness.text()) || 1;
            root.show("brightness", Number(text()) / max, false);
        }
    }

    // ── the popup ──
    LazyLoader {
        active: root.shown

        PanelWindow {
            screen: Niri.focusedScreen
            // full-width strip so the pill centers reliably; empty input mask
            // so the invisible parts never eat clicks meant for windows below
            anchors {
                left: true
                right: true
                bottom: true
            }
            margins.bottom: 96
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"
            implicitHeight: 52
            mask: Region {}

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: osdContent.implicitWidth + 36
                height: 52
                radius: Theme.islandRadius
                color: Theme.alpha(Theme.base, 0.96)
                border.width: 1
                border.color: Theme.surface0

                Row {
                    id: osdContent
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        text: {
                            if (root.kind === "brightness")
                                return "󰃟";
                            if (root.kind === "mic")
                                return Theme.micIcon(root.muted);
                            return Theme.volumeIcon(root.value, root.muted);
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 4
                        color: root.muted ? Theme.overlay0
                             : root.kind === "brightness" ? Theme.yellow
                             : Theme.teal
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 180
                        height: 6
                        radius: 3
                        color: Theme.surface0

                        Rectangle {
                            width: parent.width * Math.min(1, root.value)
                            height: parent.height
                            radius: 3
                            color: root.muted ? Theme.overlay0
                                 : root.kind === "brightness" ? Theme.yellow
                                 : Theme.teal
                            Behavior on width {
                                NumberAnimation { duration: 80 }
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.muted && root.kind !== "brightness"
                            ? "muted" : Math.round(root.value * 100) + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        color: Theme.subtext0
                    }
                }
            }
        }
    }
}
