pragma ComponentBehavior: Bound
// Background-layer wallpaper on every output (replaces swaybg). Paths come from
// Services/Wallpapers.qml, which allows a per-output override; change them
// with `qs ipc call wallpaper set|setOn` or the Mod+Shift+W picker.
//
// Two images per output crossfade on change instead of a hard cut, each is
// decoded at the output's own device height rather than at full 4K three
// times over, and a missing or unreadable file falls back to a palette
// gradient instead of flat crust.
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

            // `win`, not `parent`: inside a PanelWindow, `parent` is the
            // content item and has no modelData
            readonly property string wanted: Wallpapers.forOutput(win.modelData.name)
            property bool broken: false

            screen: modelData
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "qs-wallpaper"
            color: Theme.crust

            // fallback: no path, or the file failed to load
            Rectangle {
                anchors.fill: parent
                visible: win.broken || win.wanted === ""
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.base }
                    GradientStop { position: 1.0; color: Theme.crust }
                }
            }

            component Wall: Image {
                id: wall

                property Wall other

                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop   // swaybg -m fill
                asynchronous: true
                cache: false
                // Height only: with both dimensions set Qt fits INSIDE the box,
                // and a 16:9 image on the 16:10 laptop panel would be upscaled
                // after the crop. Blur-free, so full device height.
                sourceSize.height: Math.ceil(win.modelData.height * win.modelData.devicePixelRatio)
                opacity: 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durationLong * 2
                        easing.type: Easing.InOutQuad
                        // free the faded-out image's memory once it's invisible
                        onRunningChanged: if (!running && wall.opacity === 0) wall.source = ""
                    }
                }

                onStatusChanged: {
                    if (status === Image.Ready) {
                        win.broken = false;
                        opacity = 1;
                        if (other)
                            other.opacity = 0;
                    } else if (status === Image.Error) {
                        console.warn("wallpaper: cannot load " + source);
                        win.broken = true;
                    }
                }
            }

            Wall { id: img0; other: img1 }
            Wall { id: img1; other: img0 }

            // the back image loads the new file and fades in over the front one
            function swap() {
                if (wanted === "") {
                    img0.opacity = 0;
                    img1.opacity = 0;
                    return;
                }
                const back = img0.opacity > 0 ? img1 : img0;
                back.source = wanted;
            }

            onWantedChanged: swap()
            Component.onCompleted: swap()
        }
    }
}
