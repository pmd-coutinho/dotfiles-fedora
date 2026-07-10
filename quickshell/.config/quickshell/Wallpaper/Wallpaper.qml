pragma ComponentBehavior: Bound
// Background-layer wallpaper on every output (replaces swaybg).
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Theme

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
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
                source: Quickshell.env("HOME") + "/Pictures/wallpapers/cat-waves.png"
                fillMode: Image.PreserveAspectCrop   // swaybg -m fill
                asynchronous: true
            }
        }
    }
}
