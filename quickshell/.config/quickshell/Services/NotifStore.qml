pragma Singleton
// Notification history on disk, so a shell restart (which this config gets a
// lot of — see README "restarting quickshell") no longer wipes the list.
//
// Plain JSON written with FileView.setText, debounced, atomic. Not a
// JsonAdapter: that binds two ways and would re-load what we just wrote.
// Only fields that survive a restart are stored — the live Notification
// object, its actions and any image:// provider URL die with the process.
// File: { version, lastSeen, entries: [...] } (a bare array is accepted too).
//
// Hand-off is pull-based: `loaded` flips once the file has been read and
// Notifs merges `entries` whenever it sees that, whichever of the two
// singletons came up first. Until Notifs reports `applied`, save() is a
// no-op — an early empty save must never clobber the previous session.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string file: Quickshell.statePath("notifications.json")
    readonly property int maxEntries: 200
    readonly property int maxAgeMs: 7 * 86400000

    property bool loaded: false
    property bool applied: false
    property var entries: []
    property double lastSeen: 0

    FileView {
        id: view
        path: root.file
        atomicWrites: true
        printErrors: false

        onLoaded: {
            if (root.loaded)
                return;
            let arr = [];
            let seen = 0;
            try {
                const parsed = JSON.parse(text());
                if (Array.isArray(parsed)) {
                    arr = parsed;
                } else if (parsed && typeof parsed === "object") {
                    arr = Array.isArray(parsed.entries) ? parsed.entries : [];
                    seen = Number(parsed.lastSeen) || 0;
                }
            } catch (e) {
                console.warn("NotifStore: " + root.file + " unreadable, starting empty");
            }
            const cutoff = Date.now() - root.maxAgeMs;
            root.entries = arr.filter(e => e && typeof e.time === "number" && e.time > cutoff)
                              .slice(-root.maxEntries);
            root.lastSeen = seen;
            root.loaded = true;
        }
        // first run: nothing on disk yet
        onLoadFailed: {
            if (root.loaded)
                return;
            root.entries = [];
            root.loaded = true;
        }
        onSaveFailed: console.warn("NotifStore: could not write " + root.file)
    }

    property var pending: null

    Timer {
        id: debounce
        interval: 1000
        onTriggered: root.writeNow()
    }

    function writeNow() {
        if (root.pending === null)
            return;
        view.setText(JSON.stringify(root.pending));
        root.pending = null;
    }

    // `records` are Notifs' in-memory records; strip them to the persistable
    // subset. Transient ones never reach the disk.
    function save(records, lastSeen) {
        if (!applied)
            return;
        pending = {
            version: 1,
            lastSeen: lastSeen ?? 0,
            entries: records
                .filter(r => r && !r.transient)
                .slice(-maxEntries)
                .map(r => ({
                    id: r.id,
                    time: r.time,
                    appName: r.appName,
                    appIcon: r.appIcon,
                    desktopEntry: r.desktopEntry,
                    summary: r.summary,
                    body: r.body,
                    urgency: r.urgency,
                    image: /^(file:\/\/|\/)/.test(r.image ?? "") ? r.image : ""
                }))
        };
        debounce.restart();
    }

    function flush() {
        if (debounce.running) {
            debounce.stop();
            writeNow();
        }
    }
}
