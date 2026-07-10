//@ pragma IconTheme Papirus-Dark
// Quickshell root — replaces waybar/swaync/swaybg/swayidle/wlogout in phases
// (see README). Components load lazily via Loaders to keep one lean process.
import Quickshell
import Quickshell.Io
import QtQuick
import qs.Bar
import qs.Idle
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
}
