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

    // Show an OSD when caps lock toggles. This is also what keeps the caps-lock
    // LED poll (Services/Keyboard.qml, 3 reads/s) running outside the lock
    // screen — turn it off to have the poll only while locked.
    readonly property bool capsOsd: true

    // Night light colour temperature (wlsunset -t); shown in the control center.
    readonly property int nightLightKelvin: 4000

    // How many toasts stack on screen before the rest collapse into "+N more".
    readonly property int maxPopups: 3

    // Minutes offered by the timed do-not-disturb page.
    readonly property var dndPresets: [30, 60, 120]
}
