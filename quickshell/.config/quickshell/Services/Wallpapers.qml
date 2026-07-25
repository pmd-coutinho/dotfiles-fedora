pragma Singleton
// Wallpaper paths + the accent colour derived from them.
//
// The path used to be a string literal in two files (Wallpaper/Wallpaper.qml and
// Lock/Lock.qml), so the lockscreen and the desktop could silently disagree.
// Now it comes from wallpaper.json next to shell.qml, optionally per output:
//
//   { "wallpaper": "~/Pictures/wallpapers/cat-waves.png",
//     "perOutput": { "eDP-1": "~/Pictures/wallpapers/other.png" } }
//
// Change it at runtime with:
//   qs ipc call wallpaper set   ~/Pictures/wallpapers/foo.png
//   qs ipc call wallpaper setOn DP-2 ~/Pictures/wallpapers/bar.png
//
// `accent` is quantized out of the primary wallpaper — the dynamic-theming bit
// that would otherwise need matugen, except ColorQuantizer ships with
// quickshell. Catppuccin stays the base palette; only accents follow the image,
// so Theme.qml remains generated from palette/catppuccin-mocha.env.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Theme

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") ?? ""

    // JsonAdapter gives us the file as properties and writes it back on change
    readonly property string primary: expand(cfg.wallpaper)

    function expand(p) {
        const s = (p ?? "").trim();
        if (s === "")
            return "";
        return s.startsWith("~/") ? home + s.slice(1) : s;
    }

    // desktop and lockscreen both go through here
    function forOutput(name) {
        const per = cfg.perOutput ?? ({});
        const own = expand(per[name]);
        return own !== "" ? own : primary;
    }

    function set(path) {
        cfg.wallpaper = path;
        view.writeAdapter();
    }

    function setOn(output, path) {
        // JsonAdapter needs a fresh object to notice the change
        const next = Object.assign({}, cfg.perOutput ?? ({}));
        next[output] = path;
        cfg.perOutput = next;
        view.writeAdapter();
    }

    FileView {
        id: view
        path: (root.home === "" ? "" : root.home + "/.config/quickshell/wallpaper.json")
        watchChanges: true
        onFileChanged: reload()

        adapter: JsonAdapter {
            id: cfg
            property string wallpaper: ""
            property var perOutput: ({})
        }
    }

    // ── accent from the wallpaper ──
    // ColorQuantizer quantizes once and does NOT re-run when its `source`
    // changes (verified: setting a magenta wallpaper at runtime left a blue
    // accent until the shell restarted). So rebuild the object instead of
    // reassigning its source — toggling the Loader is what forces a fresh
    // quantization.
    Loader {
        id: quantLoader

        active: root.primary !== ""
        sourceComponent: ColorQuantizer {
            source: "file://" + root.primary
            // 4 → up to 16 buckets: enough to find a vivid colour without
            // turning the whole image into mush
            depth: 4
        }
    }

    onPrimaryChanged: {
        if (root.primary === "")
            return;
        quantLoader.active = false;
        quantLoader.active = true;
    }

    // The Catppuccin accents, in palette order. The wallpaper picks WHICH of
    // these to use; it never introduces a colour of its own. Quantizing a photo
    // yields things like #3c61d9 — legible, but visibly not Mocha sitting next
    // to the rest of the bar. Snapping keeps the shell coherent while still
    // following the image.
    readonly property var accentPalette: [
        Theme.rosewater, Theme.flamingo, Theme.pink, Theme.mauve, Theme.red,
        Theme.maroon, Theme.peach, Theme.yellow, Theme.green, Theme.teal,
        Theme.sky, Theme.sapphire, Theme.blue, Theme.lavender
    ]

    // Dominant colour of the wallpaper, before snapping. Depends on `primary` as
    // well as the quantizer output: ColorQuantizer doesn't re-notify when only
    // its source changes, so without that dependency a runtime wallpaper change
    // left the previous accent in place until the shell restarted.
    readonly property color rawAccent: {
        const cs = quantLoader.item?.colors ?? [];
        let best = null;
        let bestScore = -1;
        for (const c of cs) {
            // ignore near-black/near-white and washed-out buckets: quantized
            // palettes are mostly muddy averages and the first bucket is usually
            // grey
            if (c.hslLightness < 0.25 || c.hslLightness > 0.85)
                continue;
            if (c.hslSaturation < 0.25)
                continue;
            // favour saturation, mildly penalise straying from mid lightness
            const score = c.hslSaturation - Math.abs(c.hslLightness - 0.55) * 0.5;
            if (score > bestScore) {
                bestScore = score;
                best = c;
            }
        }
        return best ?? Theme.mauve;
    }

    // Nearest palette accent by hue, with lightness/saturation as a weak
    // tie-break — hue is what makes "blue wallpaper → blue accent" read right,
    // and comparing straight RGB distance tends to land on whichever palette
    // entry happens to be darkest.
    readonly property color accent: {
        const target = rawAccent;
        let best = Theme.mauve;
        let bestDist = Number.MAX_VALUE;
        for (const c of accentPalette) {
            let dh = Math.abs(c.hslHue - target.hslHue);
            if (dh > 0.5)
                dh = 1.0 - dh;   // hue is circular
            const dist = dh * 3.0
                + Math.abs(c.hslSaturation - target.hslSaturation) * 0.5
                + Math.abs(c.hslLightness - target.hslLightness) * 0.5;
            if (dist < bestDist) {
                bestDist = dist;
                best = c;
            }
        }
        return best;
    }
}
