//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
// Quickshell root — replaces waybar/swaync/swaybg/swayidle/wlogout in phases
// (see README). Components load lazily via Loaders to keep one lean process.
import Quickshell
import QtQuick
import qs.Bar

ShellRoot {
    // Phase 1: the bar. Notifications, OSD, wallpaper, idle, lock follow.
    Bar {}
}
