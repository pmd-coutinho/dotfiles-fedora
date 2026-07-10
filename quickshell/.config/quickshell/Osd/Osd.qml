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

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() {
            root.show("volume", root.sink.audio.volume, root.sink.audio.muted);
        }
        function onMutedChanged() {
            root.show("volume", root.sink.audio.volume, root.sink.audio.muted);
        }
    }

    Connections {
        target: root.source?.audio ?? null
        function onMutedChanged() {
            root.show("mic", root.source.audio.volume, root.source.audio.muted);
        }
    }

    // ── brightness (sysfs watch) ──
    FileView {
        id: maxBrightness
        path: "/sys/class/backlight/intel_backlight/max_brightness"
        blockLoading: true
    }

    FileView {
        id: brightness
        path: "/sys/class/backlight/intel_backlight/brightness"
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
            screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput)
                ?? Quickshell.screens[0]
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
                                return root.muted ? "󰍭" : "󰍬";
                            if (root.muted)
                                return "󰝟";
                            return root.value <= 0.33 ? "󰕿" : root.value <= 0.66 ? "󰖀" : "󰕾";
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
