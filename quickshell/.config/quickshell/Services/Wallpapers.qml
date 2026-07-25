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
    ColorQuantizer {
        id: quantizer
        source: root.primary === "" ? "" : "file://" + root.primary
        // 4 → up to 16 buckets: enough to find a vivid colour without turning
        // the whole image into mush
        depth: 4
    }

    // Prefer a saturated, mid-lightness colour: quantized palettes are mostly
    // muddy averages, and picking the first bucket usually yields grey. Falls
    // back to the Catppuccin accent when there is no usable candidate (no
    // wallpaper, or a monochrome one).
    readonly property color accent: {
        const cs = quantizer.colors ?? [];
        let best = null;
        let bestScore = -1;
        for (const c of cs) {
            // ignore near-black/near-white and washed-out buckets
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
}
