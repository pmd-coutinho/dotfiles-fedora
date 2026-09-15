pragma Singleton
// Notification history on disk, so a shell restart (which this config gets a
// lot of — see README "restarting quickshell") no longer wipes the list.
//
// Plain JSON written with FileView.setText, debounced, atomic. Not a
// JsonAdapter: that binds two ways and would re-load what we just wrote.
// Only fields that survive a restart are stored — the live Notification
// object, its actions and any image:// provider URL die with the process.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string file: Quickshell.statePath("notifications.json")
    readonly property int maxEntries: 200
    readonly property int maxAgeMs: 7 * 86400000
    property bool loaded: false

    // emitted once with the entries that were on disk (already pruned)
    signal restored(var entries)

    FileView {
        id: view
        path: root.file
        atomicWrites: true
        printErrors: false

        onLoaded: {
            if (root.loaded)
                return;
            let arr = [];
            try {
                arr = JSON.parse(text());
                if (!Array.isArray(arr))
                    arr = [];
            } catch (e) {
                console.warn("NotifStore: " + root.file + " unreadable, starting empty");
            }
            const cutoff = Date.now() - root.maxAgeMs;
            root.loaded = true;
            root.restored(arr.filter(e => e && typeof e.time === "number" && e.time > cutoff)
                             .slice(-root.maxEntries));
        }
        // first run: nothing on disk yet
        onLoadFailed: {
            if (root.loaded)
                return;
            root.loaded = true;
            root.restored([]);
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
    function save(records) {
        pending = records
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
            }));
        debounce.restart();
    }

    function flush() {
        if (debounce.running) {
            debounce.stop();
            writeNow();
        }
    }
}
