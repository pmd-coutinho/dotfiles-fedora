pragma ComponentBehavior: Bound
// On-screen display for value changes: volume / mic / brightness levels, and
// state flips the bar alone would let you miss — caps lock, do-not-disturb,
// caffeine, night light, the power profile, and play/pause with the track.
//
// Every kind is one entry in `kinds` (icon, colour, whether it has a bar, how
// to label the payload); Osd.show(kind, payload) is the single entry point,
// reachable from other components through Bus.osd and from scripts through
// `qs ipc call osd show <kind> <value>`. The OSD also subscribes itself to the
// services, so nothing else has to remember to call it. Media keys keep
// calling wpctl/brightnessctl unchanged — the OSD only observes.
//
// The pill is a fixed width so "100%" → "muted" doesn't jitter, and the window
// stays mounted through the exit animation (`mounted` outlives `shown`).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.Components
import qs.Services
import qs.Theme

Scope {
    id: root

    readonly property var kinds: ({
        volume: {
            icon: v => Icons.volume(Math.min(1, v.value ?? 0), v.muted ?? false),
            color: Theme.teal, bar: true, timeout: 1500,
            label: v => (v.muted ?? false) ? "muted" : Math.round((v.value ?? 0) * 100) + "%"
        },
        mic: {
            icon: v => Icons.mic(v.muted ?? false),
            color: Theme.teal, bar: true, timeout: 1500,
            label: v => (v.muted ?? false) ? "muted" : Math.round((v.value ?? 0) * 100) + "%"
        },
        brightness: {
            icon: v => Icons.brightness,
            color: Theme.yellow, bar: true, timeout: 1500,
            label: v => Math.round((v.value ?? 0) * 100) + "%"
        },
        caps: {
            icon: v => Icons.capsLock,
            color: Theme.warning, bar: false, timeout: 1200,
            label: v => v.on ? "caps lock on" : "caps lock off"
        },
        media: {
            icon: v => v.playing ? Icons.play : Icons.pause,
            color: Theme.pink, bar: false, timeout: 2500,
            label: v => v.title ?? ""
        },
        dnd: {
            icon: v => v.on ? Icons.bellOff : Icons.bell,
            color: Theme.accent, bar: false, timeout: 1500,
            label: v => v.on ? "do not disturb" : "notifications on"
        },
        caffeine: {
            icon: v => v.on ? Icons.caffeineOn : Icons.caffeineOff,
            color: Theme.accent, bar: false, timeout: 1500,
            label: v => v.on ? "caffeine on" : "caffeine off"
        },
        nightlight: {
            icon: v => Icons.nightLight(v.on),
            color: Theme.warning, bar: false, timeout: 1500,
            label: v => v.on ? "night light on" : "night light off"
        },
        power: {
            icon: v => v.profile === PowerProfile.Performance ? Icons.profilePerformance
                     : v.profile === PowerProfile.PowerSaver ? Icons.profileSaver
                     : Icons.profileBalanced,
            color: Theme.warning, bar: false, timeout: 1500,
            label: v => v.profile === PowerProfile.Performance ? "performance"
                      : v.profile === PowerProfile.PowerSaver ? "power saver"
                      : "balanced"
        }
    })

    property string kind: "volume"
    property var payload: ({})
    readonly property var spec: kinds[kind] ?? kinds.volume
    readonly property real value: Number(payload.value ?? 0)
    readonly property bool muted: payload.muted ?? false
    // volume can go past 100%: the bar shows the excess in the warning colour
    readonly property real maxShown: Math.max(1, value)

    property bool shown: false
    property bool mounted: false
    // suppress the initial property-change flurry while services connect
    property bool armed: false

    function show(kind, payload) {
        if (!armed || !kinds[kind])
            return;
        root.kind = kind;
        root.payload = payload ?? ({});
        hideTimer.interval = spec.timeout;
        hideTimer.restart();
        if (shown)
            return;             // repeated presses only extend the timer
        unmount.stop();
        if (!mounted) {
            mounted = true;
            arm.restart();      // let the surface map, then animate in
        } else {
            shown = true;
        }
    }

    Timer {
        id: arm
        interval: 16
        onTriggered: root.shown = true
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: {
            root.shown = false;
            unmount.restart();
        }
    }

    Timer {
        id: unmount
        interval: Theme.durationMedium + 50
        onTriggered: if (!root.shown) root.mounted = false
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
        function onVolumeChanged() { root.showAudio("volume", root.sink?.audio); }
        function onMutedChanged() { root.showAudio("volume", root.sink?.audio); }
    }

    Connections {
        target: root.source?.audio ?? null
        function onVolumeChanged() { root.showAudio("mic", root.source?.audio); }
        function onMutedChanged() { root.showAudio("mic", root.source?.audio); }
    }

    function showAudio(kind, audio) {
        if (audio)
            show(kind, { value: audio.volume, muted: audio.muted });
    }

    // ── everything else ──
    Connections {
        target: Backlight
        function onChangedExternally(level) { root.show("brightness", { value: level }); }
    }
    Connections {
        target: Keyboard
        function onCapsLockChanged() { if (Config.capsOsd) root.show("caps", { on: Keyboard.capsLock }); }
    }
    Connections {
        target: Notifs
        function onDndChanged() { root.show("dnd", { on: Notifs.dnd }); }
    }
    Connections {
        target: Caffeine
        function onActiveChanged() { root.show("caffeine", { on: Caffeine.active }); }
    }
    Connections {
        target: NightLight
        function onOnChanged() { root.show("nightlight", { on: NightLight.on }); }
    }
    Connections {
        target: PowerProfiles
        function onProfileChanged() { root.show("power", { profile: PowerProfiles.profile }); }
    }
    Connections {
        target: Media.player
        function onIsPlayingChanged() { root.showMedia(); }
        function onPostTrackChanged() { if (Media.player?.isPlaying) root.showMedia(); }
    }

    function showMedia() {
        const p = Media.player;
        if (!p)
            return;
        const t = p.trackTitle ?? "";
        const a = p.trackArtist ?? "";
        show("media", { playing: p.isPlaying, title: t === "" ? (p.identity ?? "") : (a !== "" ? a + " — " + t : t) });
    }

    // ── the popup ──
    LazyLoader {
        active: root.mounted

        PanelWindow {
            screen: Niri.focusedScreen
            // full-width strip so the pill centres reliably; empty input mask
            // so the invisible parts never eat clicks meant for windows below
            anchors {
                left: true
                right: true
                bottom: true
            }
            margins.bottom: 96
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-osd"
            color: "transparent"
            implicitHeight: 52 + 24 + Theme.shadowBlur2
            mask: Region {}

            Surface {
                id: pill

                elevation: 2
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300
                height: 52
                radius: height / 2
                y: root.shown ? 12 : 32
                opacity: root.shown ? 1 : 0

                Behavior on y {
                    NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easeStandard }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.durationMedium }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingLg
                    anchors.rightMargin: Theme.spacingLg
                    spacing: Theme.spacingMd

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        glyph: root.spec.icon(root.payload)
                        size: Theme.iconSizeLg
                        color: root.muted ? Theme.textMuted : root.spec.color
                    }

                    SliderBar {
                        visible: root.spec.bar
                        anchors.verticalCenter: parent.verticalCenter
                        width: 300 - 2 * Theme.spacingLg - 24 - 56 - 2 * Theme.spacingMd
                        interactive: false
                        // the track spans 0..maxShown; past 100% the fill continues
                        // in the warning colour with a tick at the 100% mark
                        value: root.muted ? 0 : Math.min(root.value, root.maxShown) / root.maxShown
                        overflowFrom: root.maxShown > 1 ? 1 / root.maxShown : 0
                        color: root.muted ? Theme.textMuted : root.spec.color
                        trackColor: Theme.surface1
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.spec.bar ? 56 : 300 - 2 * Theme.spacingLg - 24 - Theme.spacingMd
                        horizontalAlignment: root.spec.bar ? Text.AlignRight : Text.AlignLeft
                        elide: Text.ElideRight
                        text: root.spec.label(root.payload)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        font.weight: root.spec.bar ? Theme.weightRegular : Theme.weightMedium
                        color: root.value > 1 && root.spec.bar ? Theme.warning : Theme.textSecondary
                    }
                }
            }
        }
    }
}
