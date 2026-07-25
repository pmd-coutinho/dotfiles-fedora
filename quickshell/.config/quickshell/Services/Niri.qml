pragma Singleton
// niri IPC — event-stream socket kept in sync with compositor state.
// niri has no built-in quickshell module (unlike Hyprland); this is the
// standard community pattern (cf. DankMaterialShell's NiriService).
//
// Why this isn't Quickshell.WindowManager (the ext-workspace-v1 module, which
// niri does implement): ext-workspace has no concept of a FOCUSED output, only
// a per-group active workspace, and Toplevel has no activate() in 0.3.0. The
// bar needs the focused output (OSD/session menu/panel placement) and each
// output's own active window title, so the event stream has to stay — and
// having both would mean two sources of truth for the same workspace list.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // raw niri objects: workspaces have id/idx/name/output/is_active/
    // is_focused/is_urgent/active_window_id; windows have id/title/app_id/
    // workspace_id/is_focused/is_urgent
    //
    // Read-only to consumers: only handleEvent() may write, so a widget can't
    // stomp compositor state.
    readonly property var workspaces: _workspaces
    readonly property var windows: _windows

    property var _workspaces: []
    property var _windows: []

    readonly property string focusedOutput: workspaces.find(w => w.is_focused)?.output ?? ""

    // The ShellScreen behind focusedOutput, for the popups that follow focus
    // (OSD, session menu, notification toasts). Three files had this same
    // find()-with-fallback inline. Falls back to the first screen before the
    // event stream has told us anything.
    readonly property var focusedScreen:
        Quickshell.screens.find(s => s.name === focusedOutput) ?? Quickshell.screens[0] ?? null

    function workspacesOn(output) {
        return workspaces.filter(w => w.output === output);
    }

    // title shown in the bar of a given output: the active window of that
    // output's active workspace (matches waybar niri/window separate-outputs)
    function activeWindowTitleOn(output) {
        const ws = workspaces.find(w => w.output === output && w.is_active);
        if (!ws || ws.active_window_id === null || ws.active_window_id === undefined)
            return "";
        const win = windows.find(w => w.id === ws.active_window_id);
        return win?.title ?? "";
    }

    function focusWorkspace(ws) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", ws.name ?? String(ws.idx)]);
    }

    // NIRI_SOCKET is unset when qs is started outside a niri session (e.g. from
    // a rescue TTY) — then we never connect at all rather than spamming errors.
    readonly property string socketPath: Quickshell.env("NIRI_SOCKET") ?? ""
    property bool _wantConnect: socketPath !== ""

    Socket {
        path: root.socketPath
        connected: root._wantConnect
        onConnectionStateChanged: {
            if (connected) {
                write('"EventStream"\n');
                flush();
                return;
            }
            // The socket dropped (niri restarted, or it wasn't up yet). Without
            // this the bar kept showing whatever workspaces existed at the
            // moment of the drop, forever. Clear the stale state and retry.
            if (root.socketPath === "")
                return;
            root._workspaces = [];
            root._windows = [];
            root._wantConnect = false;
            reconnect.start();
        }

        parser: SplitParser {
            onRead: line => {
                let event;
                try {
                    event = JSON.parse(line);
                } catch (e) {
                    return;
                }
                root.handleEvent(event);
            }
        }
    }

    Timer {
        id: reconnect
        interval: 1000
        onTriggered: root._wantConnect = true
    }

    function handleEvent(event) {
        const type = Object.keys(event)[0];
        const data = event[type];
        switch (type) {
        case "WorkspacesChanged": {
            // niri resends the full list; preserve active_window_id we've
            // learned from WorkspaceActiveWindowChanged where niri omits it
            const old = {};
            for (const w of _workspaces)
                old[w.id] = w;
            _workspaces = data.workspaces
                .map(w => (w.active_window_id === undefined && old[w.id])
                    ? Object.assign({}, w, { active_window_id: old[w.id].active_window_id })
                    : w)
                .sort((a, b) => a.idx - b.idx);
            break;
        }
        case "WorkspaceActivated": {
            // resolve the activated workspace's output ONCE — this used to be a
            // find() inside the map(), i.e. O(n²) on every workspace switch
            const target = _workspaces.find(w => w.id === data.id);
            if (!target)
                break;
            _workspaces = _workspaces.map(w => {
                const sameOutput = w.output === target.output;
                if (!sameOutput && !data.focused)
                    return w;
                const next = Object.assign({}, w);
                // only one workspace per output is active
                if (sameOutput)
                    next.is_active = w.id === data.id;
                // ...and only one across all outputs is focused
                if (data.focused)
                    next.is_focused = w.id === data.id;
                return next;
            });
            break;
        }
        case "WorkspaceActiveWindowChanged":
            _workspaces = _workspaces.map(w => w.id === data.workspace_id
                ? Object.assign({}, w, { active_window_id: data.active_window_id })
                : w);
            break;
        case "WorkspaceUrgencyChanged":
            _workspaces = _workspaces.map(w => w.id === data.id
                ? Object.assign({}, w, { is_urgent: data.urgent })
                : w);
            break;
        case "WindowsChanged":
            _windows = data.windows;
            break;
        case "WindowOpenedOrChanged": {
            const win = data.window;
            let found = false;
            let next = _windows.map(w => {
                if (w.id === win.id) {
                    found = true;
                    return win;
                }
                return win.is_focused ? Object.assign({}, w, { is_focused: false }) : w;
            });
            if (!found)
                next.push(win);
            _windows = next;
            break;
        }
        case "WindowClosed":
            _windows = _windows.filter(w => w.id !== data.id);
            break;
        case "WindowFocusChanged":
            _windows = _windows.map(w => (!!w.is_focused !== (w.id === data.id))
                ? Object.assign({}, w, { is_focused: w.id === data.id })
                : w);
            break;
        case "WindowUrgencyChanged":
            _windows = _windows.map(w => w.id === data.id
                ? Object.assign({}, w, { is_urgent: data.urgent })
                : w);
            break;
        }
    }
}
