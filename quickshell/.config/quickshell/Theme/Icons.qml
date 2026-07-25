pragma Singleton
// Shared glyphs.
//
// Only the ones used in MORE THAN ONE file live here. A survey found 48 distinct
// nerd-font glyphs across the shell and just 7 of them duplicated, so hoisting
// the rest would push single-use, self-describing icons (the bell, the battery
// ramp, the session buttons) into a file you'd have to go and read — worse, not
// better. These seven earn it.
//
// Not generated from the palette: glyphs don't depend on colours, so this stays
// out of Theme.qml.in and render.sh's way. Nerd Font "material" glyphs
// specifically — the Font Awesome equivalents don't render in this font (see
// commit 3f4a128).
import QtQuick
import Quickshell

Singleton {
    readonly property string micOn: "󰍬"
    readonly property string micOff: "󰍭"
    readonly property string checked: "󰄲"
    readonly property string unchecked: "󰄱"
    readonly property string play: "󰐊"
    readonly property string pause: "󰏤"
    readonly property string lock: "󰌾"
    readonly property string caffeineOn: "󰅶"
    readonly property string caffeineOff: "󰛊"

    // Volume ramp: shared by the bar widget (0-100) and the OSD (0-1), which had
    // the same three-way conditional copied verbatim. `level` is 0..1.
    function volume(level, muted) {
        if (muted)
            return "󰝟";
        return level <= 0.33 ? "󰕿" : level <= 0.66 ? "󰖀" : "󰕾";
    }

    function mic(muted) {
        return muted ? micOff : micOn;
    }
}
