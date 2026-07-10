pragma Singleton
// Catppuccin Mocha tokens + shared shell metrics. RENDERED from Theme.qml.in
// by palette/render.sh — edit the .in template, never the rendered file.
import QtQuick
import Quickshell

Singleton {
    // ── palette ──
    readonly property color rosewater: "#f5e0dc"
    readonly property color flamingo: "#f2cdcd"
    readonly property color pink: "#f5c2e7"
    readonly property color mauve: "#cba6f7"
    readonly property color red: "#f38ba8"
    readonly property color maroon: "#eba0ac"
    readonly property color peach: "#fab387"
    readonly property color yellow: "#f9e2af"
    readonly property color green: "#a6e3a1"
    readonly property color teal: "#94e2d5"
    readonly property color sky: "#89dceb"
    readonly property color sapphire: "#74c7ec"
    readonly property color blue: "#89b4fa"
    readonly property color lavender: "#b4befe"
    readonly property color text: "#cdd6f4"
    readonly property color subtext1: "#bac2de"
    readonly property color subtext0: "#a6adc8"
    readonly property color overlay2: "#9399b2"
    readonly property color overlay1: "#7f849c"
    readonly property color overlay0: "#6c7086"
    readonly property color surface2: "#585b70"
    readonly property color surface1: "#45475a"
    readonly property color surface0: "#313244"
    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"

    // ── shared metrics (match the old waybar floating-islands look) ──
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int barHeight: 30
    readonly property int barMarginTop: 6
    readonly property int barMarginSide: 10
    readonly property int islandRadius: 12   // matches niri window corners
    readonly property color islandBg: Qt.alpha(base, 0.92)
    readonly property color islandBorder: Qt.alpha(surface0, 0.9)

    // translucent helper for one-off alpha shades
    function alpha(c, a) { return Qt.alpha(c, a); }
}
