pragma Singleton
// Catppuccin Mocha tokens + the shell's design system. RENDERED from Theme.qml.in
// by palette/render.sh — edit the .in template, never the rendered file.
//
// Layer-shell convention (there is no token for it: Theme must not import
// Quickshell.Wayland): Background = wallpaper; Top = the bar; Overlay = anything
// transient and dismissable — menus, tooltips, OSD, toasts, the control center,
// the session menu, polkit.
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

    // ── semantic colours ──
    // `accent` is the ONE writable token. shell.qml binds it to Wallpapers.accent
    // (the wallpaper-quantized colour, snapped to a Catppuccin accent). This file
    // cannot import qs.Services itself: Wallpapers already imports qs.Theme for
    // the snap list, and two singletons constructing each other is not a thing
    // to rely on. Defaults to mauve until the wallpaper has been quantized.
    property color accent: mauve
    readonly property color onAccent: crust
    readonly property color accentSubtle: alpha(accent, 0.18)   // "lit" bar items, selected rows
    readonly property color accentMuted: alpha(accent, 0.45)    // secondary emphasis (dots, tracks)

    readonly property color textPrimary: text
    readonly property color textSecondary: subtext0     // default glyph/label colour
    readonly property color textMuted: overlay0         // off / disabled / inactive glyphs
    readonly property color textHint: overlay1          // keybind hints, detail columns

    // Surfaces — one alpha for every card/island/panel instead of the five
    // slightly different "almost base" shades the shell used to have.
    readonly property real surfaceAlpha: 0.94
    readonly property color surface: alpha(base, surfaceAlpha)      // islands, cards, OSD, drawer
    readonly property color surfaceOverlay: alpha(mantle, 0.98)     // menus, tooltips, calendar
    readonly property color surfaceRaised: surface0                 // controls sitting on a surface
    readonly property color scrim: alpha(crust, 0.6)                // session menu, polkit
    readonly property color scrimLight: alpha(crust, 0.35)          // control center, menus
    readonly property color outline: alpha(surface0, 0.9)           // 1px borders
    readonly property color outlineSubtle: alpha(surface0, 0.6)     // dividers, separators

    readonly property color error: red
    readonly property color warning: peach
    readonly property color success: green
    readonly property color info: blue

    // ── interaction states (washes drawn over `surface`) ──
    readonly property color stateHover: alpha(text, 0.08)
    readonly property color statePressed: alpha(text, 0.14)
    readonly property color stateFocus: accent            // 1px ring on keyboard-focused rows
    readonly property real disabledOpacity: 0.45

    // ── elevation (RectangularShadow parameters, see Components/Surface.qml) ──
    readonly property color shadowColor: alpha(crust, 0.55)
    readonly property int shadowBlur1: 10                 // bar islands
    readonly property int shadowOffset1: 3
    readonly property int shadowBlur2: 22                 // menus, popups, cards
    readonly property int shadowOffset2: 8

    // ── typography ──
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    // Named by role rather than by number so a size change lands everywhere it
    // should.
    readonly property int fontTiny: fontSize - 3    // count badges, hints
    readonly property int fontSmall: fontSize - 2   // menu rows, captions
    readonly property int fontLabel: fontSize - 1   // secondary text (commonest)
    readonly property int fontMedium: fontSize + 1  // emphasised inline text
    readonly property int fontLarge: fontSize + 3   // panel headings
    readonly property int fontXLarge: fontSize + 4  // OSD glyph, media buttons
    readonly property int fontTitle: 20             // lock date, drawer header
    readonly property int fontDisplay: 96           // lock clock
    readonly property int weightRegular: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightBold: Font.Bold

    // ── sizing ──
    readonly property int iconSizeSm: 14                  // menu-row glyphs, tray-menu icons
    readonly property int iconSize: 16                    // bar glyphs, workspace app icons, tray
    readonly property int iconSizeLg: 20                  // OSD glyph, headers
    readonly property int iconSizeXl: 30                  // session buttons
    readonly property int hitMin: 24                      // minimum pointer target
    readonly property int controlHeight: 36               // switches' row, sliders' row, buttons
    readonly property int fieldHeight: 46                 // password fields

    // ── bar metrics ──
    readonly property int barHeight: 36
    readonly property int barMarginTop: 4
    readonly property int barMarginSide: 10
    // Extra reserved space BELOW the bar. 0 leaves niri's own `gaps` as the only
    // separation (see Bar.qml for the exclusive-zone arithmetic).
    readonly property int barGapBelow: 0
    readonly property int barBottom: barMarginTop + barHeight   // y where popups start
    readonly property int barShadowPad: 8                 // window extends this far below the pills
    readonly property int islandRadius: 12                // menus, cards; the bar pills are height/2
    readonly property int islandPadX: 6                   // pill inner horizontal padding
    readonly property int barItemHeight: 26               // concentric with a 36px pill (18 - 5 = 13)
    readonly property int barItemPadX: 8
    readonly property int barItemGap: 2                   // between items inside a pill
    readonly property int titleMaxWidth: 480
    readonly property int mediaMaxWidth: 260

    // ── menus / panels ──
    readonly property int rowHeight: 32                   // MenuRow
    readonly property int menuPad: 8
    readonly property int menuWidth: 320
    readonly property int menuWidthNarrow: 260            // tray, calendar
    readonly property int menuWidthWide: 360              // screen tools (label + keybind column)
    readonly property int tooltipMaxWidth: 360
    readonly property int panelWidth: 400                 // control center drawer
    readonly property int toastWidth: 400

    // ── radius scale ──
    // Pill shapes (badges, toggles, progress bars, bar items) deliberately use
    // `height / 2` at the call site instead of a token — that's the shape, not a
    // style choice.
    readonly property int radiusSmall: 6            // menu rows
    readonly property int radiusMedium: 8           // cards, tiles
    readonly property int radiusLarge: islandRadius // surfaces: menus, drawer, dialogs

    // ── motion ──
    readonly property int durationFast: 80          // level bars, colour washes
    readonly property int durationShort: 150        // toggle knobs, fades
    readonly property int durationMedium: 200       // layout moves, menus
    readonly property int durationLong: 300         // drawer, lock reveal
    readonly property int durationPulse: 900        // recording / urgent breath
    readonly property int durationTooltip: 400      // hover delay before a tip appears
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeEmphasized: Easing.OutBack
    readonly property int easeExit: Easing.InCubic

    // ── spacing scale ──
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24

    // translucent helper for one-off alpha shades
    function alpha(c, a) { return Qt.alpha(c, a); }

    // shared load ramp for the CPU/memory readouts; negative means "no reading yet"
    function loadColor(pct) {
        if (pct < 0)
            return textMuted;
        return pct >= 90 ? error : pct >= 70 ? warning : textSecondary;
    }

    // Glyphs live in Theme/Icons.qml — they don't depend on the palette, so they
    // stay out of this generated file.
}
