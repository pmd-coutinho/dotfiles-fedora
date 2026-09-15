pragma Singleton
// Notification server — quickshell owns org.freedesktop.Notifications
// (replaces swaync). Because we ARE the server, "click a notification →
// focus the app that sent it" is a lookup in Niri.windows, replacing the
// entire niri-notify-click D-Bus-eavesdropping daemon.
//
// The UI never holds a live Notification object. Every notification becomes a
// plain-JS RECORD {uid, id, time, appName, appIcon, desktopEntry, summary,
// body, urgency, image, transient, resident, notif} the moment it arrives; the
// record keeps its fields after the server destroys the object (so a toast can
// still slide out legibly) and is what NotifStore writes to disk (so history
// survives a shell restart — restored records simply have `notif: null`).
// Records are replaced, never mutated, and compared by `uid` (id@time), so
// ScriptModel-keyed lists update in place.
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.Services

Singleton {
    id: root

    // DND and the panel state survive a config reload. These used to be plain
    // properties, so every hot reload silently turned DND back off — easy to
    // miss, and this shell gets reloaded a lot while being edited.
    property alias dnd: persist.dnd
    property alias panelOpen: persist.panelOpen
    // ms epoch the timed DND ends at; 0 = indefinite (or off)
    property alias dndUntil: persist.dndUntil
    // connector name toasts are pinned to; "" = follow the focused output
    property alias popupOutput: persist.popupOutput

    PersistentProperties {
        id: persist
        reloadableId: "notifs"

        property bool dnd: false
        property bool panelOpen: false
        property double dndUntil: 0
        property string popupOutput: ""
        // arrival times by notification id, so a hot reload (which re-delivers
        // live notifications with lastGeneration=true) keeps their real time.
        // A JSON string, not an object: a persisted JS object can't cross the
        // engine boundary on reload ("JSValue can't be reassigned to another
        // engine") and came back undefined.
        property string timesJson: "{}"
    }

    function times() {
        try {
            const t = JSON.parse(persist.timesJson);
            return t && typeof t === "object" ? t : {};
        } catch (e) {
            return {};
        }
    }

    function setTime(key, time) {
        const t = times();
        if (time === undefined)
            delete t[key];
        else
            t[key] = time;
        persist.timesJson = JSON.stringify(t);
    }

    // ── records ──
    property var records: []          // oldest first
    property var popups: []           // uids currently shown as toasts, oldest first
    property var trash: []            // uids soft-deleted by Clear All, pending commit
    // time the user last looked at the list; persisted with the history
    property double lastSeen: 0
    // bumped every 30s while the list is open so relative times tick
    property double now: Date.now()

    // a record was replaced in place (notify-send -r): toasts restart their countdown
    signal refreshed(string uid)

    readonly property var history: records.filter(r => !r.transient && !trash.includes(r.uid))
    readonly property int count: history.length
    readonly property int unread: history.filter(r => r.time > lastSeen).length
    readonly property int trashCount: trash.length
    readonly property var popupRecords: popups.map(uid => find(uid)).filter(Boolean)

    function find(uid) {
        return records.find(r => r.uid === uid) ?? null;
    }

    function appKey(r) {
        return (r.desktopEntry ?? "") !== "" ? r.desktopEntry : (r.appName ?? "");
    }

    // ── grouping ──
    // Toasts collapse same app + summary (consecutive Slack messages from one
    // sender) into one card with a count; the history list groups per app so
    // a chat app with many senders is one expandable block.
    function groupList(arr, keyFn) {
        const groups = [];
        const idx = new Map();
        for (const r of arr) {
            const key = keyFn(r);
            if (idx.has(key)) {
                const g = groups[idx.get(key)];
                g.count += 1;
                g.entries.push(r);
                // by time, so it holds for oldest-first (toasts) and
                // newest-first (history) input alike
                if (r.time >= g.latest.time)
                    g.latest = r;
            } else {
                idx.set(key, groups.length);
                groups.push({
                    key: key, latest: r, count: 1, entries: [r],
                    appName: r.appName, appIcon: r.appIcon, appKey: appKey(r)
                });
            }
        }
        return groups;
    }

    function section(r) {
        return new Date(r.time).toDateString() === new Date(now).toDateString() ? "Today" : "Earlier";
    }

    readonly property var popupGroups: groupList(popupRecords, r => appKey(r) + "|" + r.summary)
    readonly property var historyGroups: groupList(history.slice().reverse(), r => appKey(r) + "|" + r.summary)
    // newest first, per app, split into Today / Earlier
    readonly property var historyApps: groupList(history.slice().reverse(), r => section(r) + "|" + appKey(r))
        .map(g => Object.assign(g, { section: section(g.latest) }))

    // Timeout for a popup, in ms. A client may ask for a specific one via
    // expireTimeout (seconds; -1 means "you decide", 0 means "never expire").
    // Critical overrides everything and sticks until acted on.
    function timeoutFor(r) {
        if (!r)
            return 0;
        if (r.urgency === NotificationUrgency.Critical)
            return 0;
        const asked = r.notif?.expireTimeout ?? -1;
        if (asked === 0)
            return 0;
        if (asked > 0)
            return asked * 1000;
        return r.urgency === NotificationUrgency.Low ? 4000 : 8000;
    }

    // ── relative times ──
    function relTime(t) {
        const diff = Math.max(0, now - t);
        const m = Math.floor(diff / 60000);
        if (m < 1)
            return "now";
        if (m < 60)
            return m + "m ago";
        const h = Math.floor(m / 60);
        if (h < 24 && new Date(t).toDateString() === new Date(now).toDateString())
            return h + "h ago";
        const d = new Date(t);
        const yesterday = new Date(now - 86400000);
        if (d.toDateString() === yesterday.toDateString())
            return "yesterday " + Qt.formatTime(d, "HH:mm");
        if (diff < 6 * 86400000)
            return Qt.formatDateTime(d, "ddd HH:mm");
        return Qt.formatDate(d, "d MMM");
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.panelOpen
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    function markSeen() {
        lastSeen = Date.now();
        NotifStore.save(history, lastSeen);
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            now = Date.now();
            markSeen();
        } else {
            commitClear();
        }
    }

    // ── timed do-not-disturb ──
    // setDnd(true)/dnd = true is indefinite; the presets set a deadline. The
    // sunshine game-mode script uses setDnd/isDnd and needs nothing new.
    function setDndFor(minutes) {
        dnd = true;
        dndUntil = Date.now() + minutes * 60000;
    }

    function setDndUntilTomorrow() {
        const d = new Date();
        d.setDate(d.getDate() + 1);
        d.setHours(8, 0, 0, 0);
        dnd = true;
        dndUntil = d.getTime();
    }

    onDndChanged: if (!dnd) dndUntil = 0

    Timer {
        interval: 30000
        repeat: true
        running: root.dnd && root.dndUntil > 0
        triggeredOnStart: true
        onTriggered: if (Date.now() >= root.dndUntil) root.dnd = false
    }

    readonly property string dndLabel: dnd
        ? (dndUntil > 0 ? "until " + Qt.formatTime(new Date(dndUntil), "HH:mm") : "on")
        : "off"

    // ── record maintenance ──
    function snapshot(n, base) {
        return Object.assign({}, base, {
            appName: n.appName, appIcon: n.appIcon, desktopEntry: n.desktopEntry,
            summary: n.summary, body: n.body, urgency: n.urgency, image: n.image,
            transient: n.transient, resident: n.resident, notif: n
        });
    }

    function replaceRecord(next) {
        records = records.map(r => r.uid === next.uid ? next : r);
    }

    function removeRecord(uid) {
        records = records.filter(r => r.uid !== uid);
        popups = popups.filter(u => u !== uid);
        trash = trash.filter(u => u !== uid);
    }

    onHistoryChanged: NotifStore.save(history, lastSeen)

    function maybeToast(r) {
        const critical = r.urgency === NotificationUrgency.Critical;
        // DND hides popups, but a critical notification is exactly the kind
        // you must not miss, so it bypasses — it still lands in history either
        // way. The list being open also suppresses toasts: they'd appear live
        // in it, in the same corner.
        if (!critical && (dnd || panelOpen)) {
            if (r.transient)
                r.notif?.dismiss();   // suppressed and not kept: gone
            return;
        }
        if (!popups.includes(r.uid))
            popups = popups.concat([r.uid]);
    }

    // ── toast / entry actions ──
    // `transient` means "show it, don't keep it": keep it tracked (alive) while
    // its toast is up and drop it once the toast is gone.
    function hidePopup(uid) {
        popups = popups.filter(u => u !== uid);
        const r = find(uid);
        if (r?.transient)
            r.notif?.dismiss();
    }

    function hideGroupPopup(group) {
        for (const r of group.entries)
            hidePopup(r.uid);
    }

    function hidePopupsLike(r) {
        const key = appKey(r) + "|" + r.summary;
        for (const p of popupRecords)
            if (appKey(p) + "|" + p.summary === key)
                hidePopup(p.uid);
    }

    // user dismissed it: gone from toasts and history
    function dismissEntry(r) {
        popups = popups.filter(u => u !== r.uid);
        if (r.notif)
            r.notif.dismiss();       // closed → removeRecord
        else
            removeRecord(r.uid);
    }

    function dismissGroup(group) {
        for (const r of group.entries.slice())
            dismissEntry(r);
    }

    function invokeAction(r, action) {
        action.invoke();
        hidePopupsLike(r);
    }

    // click → invoke the default action (if any) and raise the source window
    function activate(r, group) {
        const def = r.notif ? (r.notif.actions.find(a => a.identifier === "default") ?? null) : null;
        if (def)
            def.invoke();
        focusSource(r);
        if (group)
            hideGroupPopup(group);
        else
            hidePopup(r.uid);
        if (!def)
            dismissEntry(r);
    }

    // ── clear with undo ──
    // Clearing soft-deletes into `trash`: the list hides those entries at once
    // and a snackbar offers Undo; after the window (or when the list closes)
    // the live objects are dismissed for real.
    function clearAll() {
        trash = trash.concat(history.map(r => r.uid));
        undoTimer.restart();
    }

    function clearApp(key) {
        trash = trash.concat(history.filter(r => appKey(r) === key).map(r => r.uid));
        undoTimer.restart();
    }

    function undoClear() {
        undoTimer.stop();
        trash = [];
    }

    function commitClear() {
        undoTimer.stop();
        if (trash.length === 0)
            return;
        const uids = trash.slice();
        trash = [];
        for (const uid of uids) {
            const r = find(uid);
            if (!r)
                continue;
            if (r.notif)
                r.notif.dismiss();
            else
                records = records.filter(x => x.uid !== uid);
        }
        NotifStore.flush();
    }

    Timer {
        id: undoTimer
        interval: 6000
        onTriggered: root.commitClear()
    }

    // port of niri-notify-click's find_window(): match desktop-entry/app_name
    // against niri window app_ids, exact first then fuzzy. Works on records,
    // so a notification restored from disk still focuses its app.
    function focusSource(r) {
        const norm = s => {
            s = (s ?? "").toLowerCase();
            return s.endsWith(".desktop") ? s.slice(0, -8) : s;
        };
        const app = norm(appKey(r));
        if (app === "")
            return;
        const appLeaf = app.split(".").pop();
        let match = null;
        for (const w of Niri.windows) {
            const aid = norm(w.app_id);
            if (aid === "")
                continue;
            if (aid === app) {
                match = w.id;
                break;
            }
            const leaf = aid.split(".").pop();
            if (match === null && appLeaf !== ""
                && (appLeaf === leaf || appLeaf === aid || app === leaf
                    || aid.includes(app) || app.includes(aid)))
                match = w.id;
        }
        if (match !== null)
            Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(match)]);
    }

    // ── restore from disk ──
    // Merge whatever NotifStore read, once, whichever singleton came up first.
    // Live notifications that arrived before the file was read keep priority
    // over their on-disk twin (same uid).
    function restore() {
        if (NotifStore.applied || !NotifStore.loaded)
            return;
        if (NotifStore.lastSeen > lastSeen)
            lastSeen = NotifStore.lastSeen;
        const have = new Set(records.map(r => r.uid));
        const olds = NotifStore.entries
            .map(e => Object.assign({}, e, {
                uid: e.id + "@" + e.time, transient: false, resident: false, notif: null
            }))
            .filter(e => !have.has(e.uid));
        NotifStore.applied = true;
        if (olds.length > 0)
            records = olds.concat(records);
        else
            NotifStore.save(history, lastSeen);
    }

    Component.onCompleted: restore()

    Connections {
        target: NotifStore
        function onLoadedChanged() {
            root.restore();
        }
    }

    readonly property NotificationServer server: NotificationServer {
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true
        inlineReplySupported: true

        onNotification: notif => {
            // Track everything, transient included: an untracked notification is
            // destroyed on the spot, and anything we hold a reference to has to
            // outlive that reference. History filters transient out instead.
            notif.tracked = true;

            const key = String(notif.id);
            const known = root.times()[key];
            const redelivered = notif.lastGeneration && known !== undefined;
            const time = redelivered ? known : Date.now();
            root.setTime(key, time);
            const uid = notif.id + "@" + time;

            const rec = root.snapshot(notif, { uid: uid, id: notif.id, time: time });
            // a restored-from-disk twin of a live notification: adopt it
            if (root.find(uid))
                root.replaceRecord(rec);
            else
                root.records = root.records.concat([rec]);

            // in-place replacement (notify-send -r, progress updates): refresh
            // the record and re-toast if it isn't currently on screen
            const resync = () => {
                const cur = root.find(uid);
                if (!cur)
                    return;
                root.replaceRecord(root.snapshot(notif, cur));
                root.refreshed(uid);
                if (!root.popups.includes(uid))
                    root.maybeToast(root.find(uid));
            };
            notif.summaryChanged.connect(resync);
            notif.bodyChanged.connect(resync);
            notif.imageChanged.connect(resync);
            notif.appIconChanged.connect(resync);
            notif.urgencyChanged.connect(resync);

            // closed by the app, by dismiss(), or by a replacement: history is
            // "notifications that are still open", as before
            notif.closed.connect(() => {
                const cur = root.find(uid);
                if (cur && cur.notif === notif)
                    root.removeRecord(uid);
                root.setTime(key, undefined);
            });

            // don't re-toast what a hot reload just re-delivered
            if (!redelivered)
                root.maybeToast(rec);
        }
    }
}
