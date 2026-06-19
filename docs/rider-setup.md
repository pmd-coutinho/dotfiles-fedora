# Rider setup (manual — Toolbox-managed, not stow-able)

Rider's `rider64.vmoptions` is **owned by JetBrains Toolbox**: it contains
per-install lines (`-Dide.managed.by.toolbox`, a notification token, a port
file) that differ per channel and are rewritten by Toolbox. So it can't be
symlinked/stowed from dotfiles without Toolbox fighting it. Apply these by hand
on a fresh machine instead — Toolbox preserves your custom edits across updates.

## Custom VM options
`Help → Edit Custom VM Options` (adds to the existing Toolbox-managed file):

```
-Xmx8192m
-Dawt.toolkit.name=WLToolkit
```

- `-Xmx8192m` — heap for NopCommerce-scale solutions (4–8 GB range). Or use
  `Help → Change Memory Settings`.
- `-Dawt.toolkit.name=WLToolkit` — pin native Wayland (don't leave it on `auto`).
  If you hit popup/window-position glitches on niri, switch to `XToolkit` and
  also export `_JAVA_AWT_WM_NONREPARENTING=1`.

> On native Wayland: turn **off** "UI settings" in Backup & Sync, or a synced
> scale/UI setting from another machine overrides your display config (blur).

## Solution-wide analysis (perf on large solutions)
`Settings → Editor → Inspection Settings`:
- Exclude Roslyn analyzers from solution-wide analysis.
- If error-highlighting still lags, toggle SWA off (status-bar widget, bottom-right).
- Mark generated / `obj` directories as excluded.

## Toolset
`Settings → Build, Execution, Deployment → Toolset and Build` — set the .NET CLI
path **explicitly** to the mise install (custom runtime, not auto), so Rider
doesn't fall back to `/usr/bin/dotnet`. Re-point after a mise SDK bump.

## Per-channel note
Each installed channel (e.g. 2026.1, 2026.2 EAP) has its own vmoptions. If you
use the EAP for real work, bump its `-Xmx` too (it defaults to ~2048m).
