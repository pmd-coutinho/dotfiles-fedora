pragma ComponentBehavior: Bound
// What one output shows while locked: the blurred wallpaper, a big clock, the
// auth card, and battery / now-playing chips along the bottom. Purely a view
// over a LockController; the same item fills a real WlSessionLockSurface
// (Lock.qml) and a plain window in the preview harness (LockPreview.qml).
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.UPower
import qs.Components
import qs.Services
import qs.Theme

Item {
    id: surface

    required property var lock
    // the ShellScreen this surface is on (for the per-output wallpaper)
    property var screen: null
    // which surface the compositor gives the keyboard to
    readonly property bool hasKeyboard: Window.active

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property int pct: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool charging: battery && battery.state === UPowerDeviceState.Charging
    readonly property var player: Media.player

    // ── background ──
    Rectangle {
        anchors.fill: parent
        color: Theme.crust
    }

    Image {
        id: bg
        anchors.fill: parent
        // same source as the desktop behind it (per output)
        source: Wallpapers.forOutput(surface.screen?.name ?? "")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        // Blur hides resolution: decode at HALF the panel's device height, a
        // quarter of the memory and blur cost of full res. Height only, so a
        // 16:9 image still covers the 16:10 laptop panel after the crop.
        sourceSize.height: Math.ceil((surface.screen?.height ?? 1080) * (surface.screen?.devicePixelRatio ?? 1) / 2)
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: bg
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        brightness: -0.35
        opacity: bg.status === Image.Ready ? surface.lock.reveal : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.durationMedium }
        }
    }

    // everything below follows the reveal
    Item {
        anchors.fill: parent
        opacity: surface.lock.reveal

        SystemClock {
            id: clock
            // minute granularity: per-second redraws keep powered-off
            // monitors from staying off (quickshell-mirror#503)
            precision: SystemClock.Minutes
        }

        // ── clock ──
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.14
            spacing: Theme.spacingXs

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontDisplay
                font.weight: Theme.weightBold
                color: Theme.textPrimary
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
                color: Theme.subtext1
            }
        }

        // ── auth ──
        AuthCard {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: parent.height * 0.08
            lock: surface.lock
            hasKeyboard: surface.hasKeyboard
        }

        // ── chips ──
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 48
            spacing: Theme.spacingSm

            component Chip: Rectangle {
                default property alias items: chipRow.data
                height: 30
                width: chipRow.implicitWidth + 2 * Theme.spacingMd
                radius: height / 2
                color: Theme.alpha(Theme.base, 0.6)
                border.width: 1
                border.color: Theme.outlineSubtle

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingXs
                }
            }

            Chip {
                visible: surface.hasBattery

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: Icons.battery(surface.pct, surface.charging)
                    size: Theme.iconSizeSm
                    color: surface.charging ? Theme.yellow
                         : surface.pct <= 10 ? Theme.error
                         : surface.pct <= 25 ? Theme.warning
                         : Theme.textSecondary
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property int secs: surface.charging ? (surface.battery?.timeToFull ?? 0) : (surface.battery?.timeToEmpty ?? 0)
                    text: surface.pct + "%" + (secs > 0
                        ? "  ·  " + Math.floor(secs / 3600) + "h " + Math.round((secs % 3600) / 60) + "m"
                          + (surface.charging ? " to full" : " left")
                        : "")
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.textSecondary
                }
            }

            Chip {
                visible: surface.player !== null

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 11
                    color: playArea.containsMouse ? Theme.stateHover : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        glyph: (surface.player?.isPlaying ?? false) ? Icons.pause : Icons.play
                        size: Theme.iconSizeSm
                        color: Theme.pink
                    }
                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: surface.player?.canTogglePlaying ?? false
                        onClicked: surface.player?.togglePlaying()
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property string t: surface.player?.trackTitle ?? ""
                    readonly property string a: surface.player?.trackArtist ?? ""
                    text: t === "" ? (surface.player?.identity ?? "") : (a !== "" ? a + " — " + t : t)
                    width: Math.min(implicitWidth, 280)
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.textSecondary
                }
            }
        }
    }
}
