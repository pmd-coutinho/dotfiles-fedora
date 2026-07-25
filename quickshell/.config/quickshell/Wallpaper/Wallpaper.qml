pragma ComponentBehavior: Bound
// Background-layer wallpaper on every output (replaces swaybg). Paths come from
// Services/Wallpapers.qml, which allows a per-output override.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services
import qs.Theme

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            color: Theme.crust

            Image {
                anchors.fill: parent
                // `win`, not `parent`: inside a PanelWindow, `parent` is the
                // content item and has no modelData
                source: Wallpapers.forOutput(win.modelData.name)
                fillMode: Image.PreserveAspectCrop   // swaybg -m fill
                asynchronous: true
            }
        }
    }
}
