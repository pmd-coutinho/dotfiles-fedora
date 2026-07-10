// Quickshell root — replaces waybar/swaync/swaybg/swayidle/wlogout in phases
// (see README). Components load lazily via Loaders to keep one lean process.
import Quickshell
import QtQuick
import qs.Theme

ShellRoot {
    // Phase 0 skeleton: proves packaging + palette rendering end to end.
    // Bar (Phase 1), notifications, OSD, wallpaper, idle, lock follow.
}
