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

    property bool dnd: false
    property bool panelOpen: false
    // notifications currently shown as popup toasts (history lives in
    // server.trackedNotifications until dismissed/cleared)
    property var popups: []

    readonly property int count: server.trackedNotifications.values.length

    // swaync timeouts: normal 8s, low 4s, critical sticks until acted on
    function timeoutFor(notif) {
        switch (notif.urgency) {
        case NotificationUrgency.Critical: return 0;
        case NotificationUrgency.Low: return 4000;
        default: return 8000;
        }
    }

    function hidePopup(notif) {
        popups = popups.filter(n => n !== notif);
    }

    // ── grouping: collapse same app + summary (e.g. consecutive Slack
    // messages from one sender) into a single card with a count ──
    function groupList(arr) {
        const groups = [];
        const idx = new Map();
        for (const n of arr) {
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
    readonly property var historyGroups: groupList(server.trackedNotifications.values.slice().reverse())

    function hideGroupPopup(group) {
        popups = popups.filter(n => !group.notifs.includes(n));
    }

    function dismissGroup(group) {
        for (const n of group.notifs.slice())
            n.dismiss();
    }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    // click → invoke the default action (if any) and raise the source window
    function activate(notif, group) {
        const def = notif.actions.find(a => a.identifier === "default") ?? null;
        if (def)
            def.invoke();
        focusSource(notif);
        if (group)
            hideGroupPopup(group);   // swaync hide-on-action
        else
            hidePopup(notif);
        if (!def)
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
            notif.tracked = true;
            notif.closed.connect(() => root.hidePopup(notif));
            if (!root.dnd)
                root.popups = root.popups.concat([notif]);
        }
    }
}
