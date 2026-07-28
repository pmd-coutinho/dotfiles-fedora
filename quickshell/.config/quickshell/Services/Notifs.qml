pragma Singleton
// Notification server — quickshell owns org.freedesktop.Notifications
// (replaces swaync). Because we ARE the server, "click a notification →
// focus the app that sent it" is a lookup in Niri.windows, replacing the
// entire niri-notify-click D-Bus-eavesdropping daemon.
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

    PersistentProperties {
        id: persist
        reloadableId: "notifs"

        property bool dnd: false
        property bool panelOpen: false
    }
    // notifications currently shown as popup toasts (history lives in
    // server.trackedNotifications until dismissed/cleared)
    property var popups: []

    // History excludes transient notifications: they're toast-only, and while
    // their toast is up they have to stay tracked (see dropIfTransient).
    readonly property var history: server.trackedNotifications.values.filter(n => n && !n.transient)

    readonly property int count: history.length

    // Timeout for a popup. A client may ask for a specific one via
    // expireTimeout (seconds; -1 means "you decide", 0 means "never expire") —
    // that used to be discarded in favour of the urgency ramp below. Critical
    // still overrides everything and sticks until acted on, matching swaync.
    function timeoutFor(notif) {
        if (!notif)
            return 0;
        if (notif.urgency === NotificationUrgency.Critical)
            return 0;
        const asked = notif.expireTimeout ?? -1;
        if (asked === 0)
            return 0;
        if (asked > 0)
            return asked * 1000;
        // swaync defaults: normal 8s, low 4s
        return notif.urgency === NotificationUrgency.Low ? 4000 : 8000;
    }

    // Notification has no timestamp property in quickshell 0.3.0, so record one
    // when it arrives — otherwise the history list can't show times at all.
    property var seenAt: new Map()

    function timeOf(notif) {
        const t = seenAt.get(notif);
        return t ? Qt.formatDateTime(t, "HH:mm") : "";
    }

    function hidePopup(notif) {
        popups = popups.filter(n => n !== notif);
        dropIfTransient(notif);
    }

    // `transient` means "show it, don't keep it". That used to be implemented by
    // untracking on arrival — but untracking destroys the notification, and the
    // toast was still holding the dead object: a blank card whose every binding
    // read from null and whose close button called dismiss() on null, so it
    // could never be cleared. Keep transient notifications tracked (alive)
    // while their toast is up and drop them once it's gone; history filters
    // them out in the meantime.
    function dropIfTransient(notif) {
        if (notif && notif.transient)
            notif.dismiss();
    }

    // ── grouping: collapse same app + summary (e.g. consecutive Slack
    // messages from one sender) into a single card with a count ──
    function groupList(arr) {
        const groups = [];
        const idx = new Map();
        for (const n of arr) {
            if (!n)
                continue;
            const key = (n.desktopEntry !== "" ? n.desktopEntry : n.appName) + "|" + n.summary;
            if (idx.has(key)) {
                const g = groups[idx.get(key)];
                g.count += 1;
                g.notifs.push(n);
                g.latest = n;
            } else {
                idx.set(key, groups.length);
                groups.push({ key: key, latest: n, count: 1, notifs: [n] });
            }
        }
        return groups;
    }

    readonly property var popupGroups: groupList(popups)
    readonly property var historyGroups: groupList(history.slice().reverse())

    function hideGroupPopup(group) {
        popups = popups.filter(n => !group.notifs.includes(n));
        for (const n of group.notifs)
            dropIfTransient(n);
    }

    function dismissGroup(group) {
        // drop the toast first, so the card always leaves the screen even if the
        // notifications behind it are already gone
        popups = popups.filter(n => !group.notifs.includes(n));
        for (const n of group.notifs.slice())
            if (n)
                n.dismiss();
    }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice())
            if (n)
                n.dismiss();
    }

    // click → invoke the default action (if any) and raise the source window
    function activate(notif, group) {
        const def = notif ? notif.actions.find(a => a.identifier === "default") ?? null : null;
        if (def)
            def.invoke();
        if (notif)
            focusSource(notif);
        if (group)
            hideGroupPopup(group);   // swaync hide-on-action
        else
            hidePopup(notif);
        if (notif && !def)
            notif.dismiss();
    }

    // port of niri-notify-click's find_window(): match desktop-entry/app_name
    // against niri window app_ids, exact first then fuzzy
    function focusSource(notif) {
        const norm = s => {
            s = (s ?? "").toLowerCase();
            return s.endsWith(".desktop") ? s.slice(0, -8) : s;
        };
        const app = norm(notif.desktopEntry !== "" ? notif.desktopEntry : notif.appName);
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

    readonly property NotificationServer server: NotificationServer {
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            // Track everything, transient included: an untracked notification is
            // destroyed on the spot, and anything we hold a reference to has to
            // outlive that reference. History filters transient out instead.
            notif.tracked = true;
            root.seenAt.set(notif, new Date());
            // Removal here is deliberately raw rather than hidePopup(): the
            // notification is already closing, so there is nothing left to drop.
            notif.closed.connect(() => {
                root.popups = root.popups.filter(n => n !== notif);
                root.seenAt.delete(notif);
            });
            // DND hides popups, but a critical notification is exactly the kind
            // you must not miss, so it bypasses — it still lands in history
            // either way.
            if (!root.dnd || notif.urgency === NotificationUrgency.Critical)
                root.popups = root.popups.concat([notif]);
            else
                root.dropIfTransient(notif);   // suppressed and not kept: gone
        }
    }
}
