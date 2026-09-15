pragma Singleton
// Shared glyphs.
//
// Two kinds of glyph live here: the ones used in more than one file, and every
// member of an enumerated SET — a ramp (wifi, battery), a family a component
// iterates over (session actions, OSD kinds), or a pair whose two halves must
// stay in step (on/off). A single-use, self-describing icon inside one widget
// can stay inline; a set gets split across files the moment it's inlined.
//
// Not generated from the palette: glyphs don't depend on colours, so this stays
// out of Theme.qml.in and render.sh's way. Nerd Font "material" glyphs
// specifically — the Font Awesome equivalents don't render in this font (see
// commit 3f4a128).
import QtQuick
import Quickshell

Singleton {
    // ── audio ──
    readonly property string micOn: "󰍬"
    readonly property string micOff: "󰍭"
    readonly property string headphones: "󰋋"
    readonly property string speaker: "󰓃"

    // Volume ramp: shared by the bar widget, the OSD and the control center.
    // `level` is 0..1.
    function volume(level, muted) {
        if (muted)
            return "󰝟";
        return level <= 0.33 ? "󰕿" : level <= 0.66 ? "󰖀" : "󰕾";
    }

    function mic(muted) {
        return muted ? micOff : micOn;
    }

    // ── media ──
    readonly property string play: "󰐊"
    readonly property string pause: "󰏤"
    readonly property string previous: "󰒮"
    readonly property string next: "󰒭"
    readonly property string playlist: "󰲸"
    readonly property string music: "󰎆"
    readonly property string raise: "󰁜"

    // ── controls / chrome ──
    readonly property string checked: "󰄲"
    readonly property string unchecked: "󰄱"
    readonly property string radioOn: "󰐾"
    readonly property string radioOff: "󰄰"
    readonly property string check: "󰄬"
    readonly property string close: "󰅖"
    readonly property string chevronRight: "󰅂"
    readonly property string chevronLeft: "󰅁"
    readonly property string chevronDown: "󰅀"
    readonly property string chevronUp: "󰅃"
    readonly property string back: "󰁍"
    readonly property string refresh: "󰑐"
    readonly property string settings: "󰒓"
    readonly property string more: "󰇘"
    readonly property string trash: "󰩺"
    readonly property string undo: "󰕌"
    readonly property string info: "󰋽"
    readonly property string warning: "󰀪"
    readonly property string eye: "󰈈"
    readonly property string eyeOff: "󰈉"
    readonly property string search: "󰍉"
    readonly property string calendar: "󰃭"
    readonly property string clock: "󰥔"
    readonly property string timer: "󰔛"
    readonly property string external: "󰏌"

    // ── session ──
    readonly property string lock: "󰌾"
    readonly property string logout: "󰗽"
    readonly property string suspend: "󰤄"
    readonly property string reboot: "󰜉"
    readonly property string poweroff: "󰐥"
    readonly property string user: ""
    readonly property string shield: "󰒃"
    readonly property string capsLock: "󰪛"
    readonly property string keyboard: "󰌌"

    // ── toggles ──
    readonly property string caffeineOn: "󰅶"
    readonly property string caffeineOff: "󰛊"
    readonly property string nightLightOn: "󰖔"
    readonly property string nightLightOff: "󰖨"
    readonly property string bell: "󰂚"
    readonly property string bellBadge: "󱅫"
    readonly property string bellOff: "󰂛"

    function nightLight(on) {
        return on ? nightLightOn : nightLightOff;
    }

    function bellIcon(dnd, hasUnread) {
        return dnd ? bellOff : hasUnread ? bellBadge : bell;
    }

    // ── power ──
    readonly property string profilePerformance: "󱐋"
    readonly property string profileBalanced: "󰾅"
    readonly property string profileSaver: "󰌪"
    readonly property string batteryCharging: "󰂄"
    readonly property string plug: "󰚥"
    readonly property var batteryRamp: ["󰁺", "󰁻", "󰁽", "󰁿", "󰂁", "󰁹"]

    // `pct` is 0..100
    function battery(pct, charging) {
        if (charging)
            return batteryCharging;
        return batteryRamp[Math.max(0, Math.min(5, Math.floor(pct / 100 * 6)))];
    }

    // ── network ──
    readonly property string wired: "󰈀"
    readonly property string wifiOff: "󰖪"
    readonly property string wifiDisabled: "󰤭"
    readonly property var wifiRamp: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

    // `signal` is 0..100
    function wifi(signal) {
        return wifiRamp[Math.max(0, Math.min(4, Math.round(signal / 25)))];
    }

    // ── bluetooth ──
    readonly property string bluetooth: "󰂯"
    readonly property string bluetoothOff: "󰂲"
    readonly property string bluetoothConnected: "󰂱"
    readonly property string mouse: "󰍽"
    readonly property string phone: "󰄜"
    readonly property string gamepad: "󰊗"
    readonly property string watch: "󰖉"

    // bluez icon names → glyph, for devices whose themed icon is missing
    function bluetoothDevice(iconName) {
        const n = (iconName ?? "").toLowerCase();
        if (n.startsWith("audio-headset") || n.startsWith("audio-headphones") || n.startsWith("audio-card"))
            return headphones;
        if (n.startsWith("input-keyboard"))
            return keyboard;
        if (n.startsWith("input-mouse") || n.startsWith("input-tablet"))
            return mouse;
        if (n.startsWith("input-gaming"))
            return gamepad;
        if (n.startsWith("phone"))
            return phone;
        if (n.startsWith("computer"))
            return "󰍹";
        return bluetooth;
    }

    // ── system ──
    readonly property string cpu: "󰻠"
    readonly property string memory: "󰍛"
    readonly property string brightness: "󰃟"
    readonly property string screenshot: "󰹑"
    readonly property string screenshotFull: "󰍹"
    readonly property string record: "󰕧"
    readonly property string recording: "󰑊"
    readonly property string stop: "󰓛"
    readonly property string ocr: "󱄽"
    readonly property string colorPick: "󰝥"
    readonly property string qr: "󰐳"
    readonly property string wallpaper: "󰸉"
    readonly property string desktop: "󰍹"
}
