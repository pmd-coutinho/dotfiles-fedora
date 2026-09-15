pragma Singleton
// Caps-lock state, for the lock screen, polkit dialog and OSD.
//
// Neither QML nor quickshell 0.3 exposes keyboard modifier state, so the only
// source is the keyboard LEDs under /sys/class/leds/*capslock/brightness. Two
// things rule out the obvious approaches:
//   - inotify (FileView.watchChanges / inotifywait) never fires: the kernel
//     input core writes the LED attribute directly, not through the VFS, so
//     there is no event to watch.
//   - the input<N> numbers in the path shuffle across reboots and USB replugs,
//     so the paths have to be globbed once, not hardcoded.
// The previous implementation was a shell `while :; do grep …; sleep 0.3` loop
// — three forks a second for the whole time the machine was locked. This does
// the same cadence as async FileView reloads (no process, ~2 bytes each), only
// while something is looking (`polling`), plus an instant refresh when a caps
// key press is seen by a focused surface (`refreshSoon()`).
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root

    property bool capsLock: false
    property var ledPaths: []

    // Poll only while a consumer can show the result.
    readonly property bool polling: Session.locked || Config.capsOsd

    // Re-glob the LED paths (a keyboard was plugged in, or we just locked).
    function rescan() {
        scan.running = false;
        scan.running = true;
    }

    // Called from a key handler that saw Qt.Key_CapsLock: the LED changes a few
    // ms after the key event, so wait a beat before reading.
    function refreshSoon() {
        soon.restart();
    }

    function recompute() {
        let on = false;
        for (let i = 0; i < readers.count; i++) {
            const v = readers.objectAt(i);
            if (v && v.text().trim() === "1") {
                on = true;
                break;
            }
        }
        capsLock = on;
    }

    function reloadAll() {
        for (let i = 0; i < readers.count; i++)
            readers.objectAt(i)?.reload();
    }

    Process {
        id: scan
        running: true
        command: ["sh", "-c", "ls /sys/class/leds/*capslock/brightness 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root.ledPaths = text.trim().split("\n").filter(p => p !== "")
        }
    }

    Instantiator {
        id: readers
        model: root.ledPaths

        FileView {
            required property string modelData
            path: modelData
            printErrors: false
            onLoaded: root.recompute()
        }
    }

    Timer {
        interval: 300
        repeat: true
        running: root.polling && root.ledPaths.length > 0
        onTriggered: root.reloadAll()
    }

    Timer {
        id: soon
        interval: 60
        onTriggered: root.reloadAll()
    }

    // A fresh lock is the moment a newly attached keyboard matters.
    Connections {
        target: Session
        function onLockedChanged() {
            if (Session.locked)
                root.rescan();
        }
    }
}
