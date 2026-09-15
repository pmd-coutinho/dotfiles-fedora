pragma Singleton
// Behavioural knobs that are not colours or metrics. They live here rather
// than in Theme.qml.in because Theme is a rendered palette artefact — changing
// an idle timeout should not require palette/render.sh.
import QtQuick
import Quickshell

Singleton {
    // Idle timeouts in seconds. `warnBefore` is how long before the lock the
    // "locking in N s" overlay appears; `screensOffLocked` applies once locked,
    // whatever the power source (a locked machine has no reason to keep three
    // monitors lit for the remainder of the 15-minute mark).
    readonly property var idle: ({
        warnBefore: 30,
        ac: { lock: 600, screensOff: 900 },
        battery: { lock: 300, screensOff: 420 },
        screensOffLocked: 60
    })

    // Toasts and the control center always open here (the laptop panel is the
    // one that's always in front of you); they fall back to the focused output
    // when it isn't connected. `qs ipc call notifs setPopupOutput` overrides
    // the toast side of this at runtime.
    readonly property string mainOutput: "eDP-1"

    // Show an OSD when caps lock toggles. This is also what keeps the caps-lock
    // LED poll (Services/Keyboard.qml, 3 reads/s) running outside the lock
    // screen — turn it off to have the poll only while locked.
    readonly property bool capsOsd: true

    // Show an OSD on play/pause and track change. Off: the bar's now-playing
    // widget and the control center's media card already show it, and a pill
    // over every song change gets old fast.
    readonly property bool mediaOsd: false

    // Night light colour temperature (wlsunset -t); shown in the control center.
    readonly property int nightLightKelvin: 4000

    // How many toasts stack on screen before the rest collapse into "+N more".
    readonly property int maxPopups: 3

    // Minutes offered by the timed do-not-disturb page.
    readonly property var dndPresets: [30, 60, 120]
}
