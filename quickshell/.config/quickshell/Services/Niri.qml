pragma Singleton
// niri IPC — event-stream socket kept in sync with compositor state.
// niri has no built-in quickshell module (unlike Hyprland); this is the
// standard community pattern (cf. DankMaterialShell's NiriService).
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // raw niri objects: workspaces have id/idx/name/output/is_active/
    // is_focused/is_urgent/active_window_id; windows have id/title/app_id/
    // workspace_id/is_focused/is_urgent
    property var workspaces: []
    property var windows: []

    readonly property string focusedOutput: workspaces.find(w => w.is_focused)?.output ?? ""

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

    Socket {
        path: Quickshell.env("NIRI_SOCKET")
        connected: true
        onConnectionStateChanged: {
            if (connected) {
                write('"EventStream"\n');
                flush();
            }
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

    function handleEvent(event) {
        const type = Object.keys(event)[0];
        const data = event[type];
        switch (type) {
        case "WorkspacesChanged": {
            // niri resends the full list; preserve active_window_id we've
            // learned from WorkspaceActiveWindowChanged where niri omits it
            const old = {};
            for (const w of workspaces)
                old[w.id] = w;
            workspaces = data.workspaces
                .map(w => (w.active_window_id === undefined && old[w.id])
                    ? Object.assign({}, w, { active_window_id: old[w.id].active_window_id })
                    : w)
                .sort((a, b) => a.idx - b.idx);
            break;
        }
        case "WorkspaceActivated":
            workspaces = workspaces.map(w => {
                const activated = w.id === data.id;
                let out = w;
                if (w.output === workspaces.find(x => x.id === data.id)?.output)
                    out = Object.assign({}, out, { is_active: activated });
                if (data.focused)
                    out = Object.assign({}, out === w ? Object.assign({}, w) : out, { is_focused: activated });
                return out;
            });
            break;
        case "WorkspaceActiveWindowChanged":
            workspaces = workspaces.map(w => w.id === data.workspace_id
                ? Object.assign({}, w, { active_window_id: data.active_window_id })
                : w);
            break;
        case "WorkspaceUrgencyChanged":
            workspaces = workspaces.map(w => w.id === data.id
                ? Object.assign({}, w, { is_urgent: data.urgent })
                : w);
            break;
        case "WindowsChanged":
            windows = data.windows;
            break;
        case "WindowOpenedOrChanged": {
            const win = data.window;
            let found = false;
            let next = windows.map(w => {
                if (w.id === win.id) {
                    found = true;
                    return win;
                }
                return win.is_focused ? Object.assign({}, w, { is_focused: false }) : w;
            });
            if (!found)
                next.push(win);
            windows = next;
            break;
        }
        case "WindowClosed":
            windows = windows.filter(w => w.id !== data.id);
            break;
        case "WindowFocusChanged":
            windows = windows.map(w => (!!w.is_focused !== (w.id === data.id))
                ? Object.assign({}, w, { is_focused: w.id === data.id })
                : w);
            break;
        case "WindowUrgencyChanged":
            windows = windows.map(w => w.id === data.id
                ? Object.assign({}, w, { is_urgent: data.urgent })
                : w);
            break;
        }
    }
}
