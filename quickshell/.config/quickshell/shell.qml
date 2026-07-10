//@ pragma IconTheme Papirus-Dark
// Quickshell root — replaces waybar/swaync/swaybg/swayidle/wlogout in phases
// (see README). Components load lazily via Loaders to keep one lean process.
import Quickshell
import Quickshell.Io
import QtQuick
import qs.Bar
import qs.Idle
import qs.Lock
import qs.Notifications
import qs.Osd
import qs.SessionMenu
import qs.Services
import qs.Wallpaper

ShellRoot {
    Wallpaper {}
    Bar {}
    Popups {}
    Panel {}
    Osd {}
    Idle {}

    SessionMenu {
        id: sessionMenu
    }

    // one global tray menu, jumps to the clicked icon's screen (see TrayMenu.qml)
    TrayMenu {
        id: trayMenu
    }

    Component.onCompleted: Bus.trayMenu = trayMenu

    // trial-mode lockscreen: `qs ipc call lock lock` — hyprlock stays the
    // active locker until this survives a week (see Lock/Lock.qml)
    Lock {
        id: lockScreen
    }

    // niri keybinds drive shell UI through `qs ipc call <target> <fn>`
    IpcHandler {
        target: "notifs"

        function toggle(): void {
            Notifs.panelOpen = !Notifs.panelOpen;
        }
        function dnd(): void {
            Notifs.dnd = !Notifs.dnd;
        }
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            sessionMenu.toggle();
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            lockScreen.lock();
        }
    }
}
