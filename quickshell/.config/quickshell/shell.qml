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
import qs.Polkit
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
    Polkit {}

    SessionMenu {
        id: sessionMenu
    }

    // one global tray menu, jumps to the clicked icon's screen (see TrayMenu.qml)
    TrayMenu {
        id: trayMenu
    }

    // audio output/input picker, same one-global-window reasoning as TrayMenu
    AudioMenu {
        id: audioMenu
    }

    // screenshot / record / OCR / colour / QR, ditto
    ScreenToolsMenu {
        id: screenToolsMenu
    }

    Component.onCompleted: {
        Bus.trayMenu = trayMenu;
        Bus.audioMenu = audioMenu;
        Bus.screenToolsMenu = screenToolsMenu;
    }

    // the session locker (idle, before-sleep and Super+Alt+L all route here
    // through Services/Session.qml — see Lock/Lock.qml for the TTY escape hatch)
    Lock {}

    // niri keybinds drive shell UI through `qs ipc call <target> <fn>`
    IpcHandler {
        target: "notifs"

        function toggle(): void {
            Notifs.panelOpen = !Notifs.panelOpen;
        }
        function dnd(): void {
            Notifs.dnd = !Notifs.dnd;
        }
        // explicit set/get for scripts that must restore the previous state
        // (sunshine/.config/sunshine/game-mode); the toggle above is for keybinds
        function setDnd(on: bool): void {
            Notifs.dnd = on;
        }
        function isDnd(): bool {
            return Notifs.dnd;
        }
    }

    // caffeine = suspend the shell's idle lock / screens-off (Services/Caffeine.qml)
    IpcHandler {
        target: "caffeine"

        function toggle(): void {
            Caffeine.toggle();
        }
        function set(on: bool): void {
            Caffeine.active = on;
        }
        function get(): bool {
            return Caffeine.active;
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
            Session.lock();
        }
    }

    // bin/screen-record pushes its state here (it owns the encoder process)
    IpcHandler {
        target: "recorder"

        function started(): void {
            Recorder.active = true;
        }
        function stopped(): void {
            Recorder.active = false;
        }
    }

    IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            Wallpapers.set(path);
        }
        function setOn(output: string, path: string): void {
            Wallpapers.setOn(output, path);
        }
        // the accent the shell derived from the current wallpaper
        function accent(): string {
            return String(Wallpapers.accent);
        }
    }
}
