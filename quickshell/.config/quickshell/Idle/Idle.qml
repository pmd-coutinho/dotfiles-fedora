pragma ComponentBehavior: Bound
// Idle management (replaces swayidle's timeouts). Timeouts live in
// Services/Config.qml, with a shorter set on battery; IdleMonitor.timeout is
// bindable, so plugging/unplugging re-arms them.
//
//   lock − warnBefore   →  dim + "locking in N s" on every output (any input cancels)
//   lock                →  Session.lock()
//   screensOff          →  monitors off
//   screensOffLocked    →  monitors off soon after a lock, whatever the source
//
// Respects the Wayland idle-inhibit protocol (video players etc.) and the
// caffeine toggle. NOTE: lock-before-sleep stays with a minimal swayidle -w in
// the niri autostart — quickshell has no logind sleep inhibitor yet, and
// locking before suspend must not race.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.Components
import qs.Services
import qs.Theme

Scope {
    id: root

    readonly property var t: UPower.onBattery ? Config.idle.battery : Config.idle.ac
    readonly property bool warning: warn.isIdle && !Session.locked && !Caffeine.active
    property int left: Config.idle.warnBefore

    function powerOff() {
        Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
    }

    // ── the warning window before the lock ──
    IdleMonitor {
        id: warn
        timeout: Math.max(5, root.t.lock - Config.idle.warnBefore)
        respectInhibitors: true
        enabled: !Caffeine.active && !Session.locked
    }

    onWarningChanged: left = Config.idle.warnBefore

    Timer {
        interval: 1000
        repeat: true
        running: root.warning
        onTriggered: root.left = Math.max(0, root.left - 1)
    }

    IdleMonitor {
        timeout: root.t.lock
        respectInhibitors: true
        enabled: !Caffeine.active
        // Session.lock() is idempotent (it just sets a bool), so the pgrep
        // guard the hyprlock era needed is gone.
        onIsIdleChanged: if (isIdle) Session.lock()
    }

    IdleMonitor {
        timeout: root.t.screensOff
        respectInhibitors: true
        enabled: !Caffeine.active
        onIsIdleChanged: if (isIdle) root.powerOff()
    }

    // once locked there is no reason to keep three monitors lit until the
    // long timeout — and the lock itself is idle-safe (minute clock, no loops)
    IdleMonitor {
        timeout: Config.idle.screensOffLocked
        respectInhibitors: false
        enabled: Session.locked
        onIsIdleChanged: if (isIdle) root.powerOff()
    }

    // ── dim + countdown on every output; click-through, so it never eats the
    // input that cancels it ──
    LazyLoader {
        active: root.warning

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
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-idle-warning"
                color: "transparent"
                mask: Region {}

                Rectangle {
                    anchors.fill: parent
                    color: Theme.crust
                    opacity: 0

                    // ramps to half-dim over the warning window
                    NumberAnimation on opacity {
                        running: true
                        to: 0.5
                        duration: Config.idle.warnBefore * 1000
                    }
                }

                Surface {
                    anchors.centerIn: parent
                    elevation: 2
                    width: box.implicitWidth + 2 * Theme.spacingXl
                    height: box.implicitHeight + 2 * Theme.spacingLg

                    Column {
                        id: box
                        anchors.centerIn: parent
                        spacing: Theme.spacingSm

                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            glyph: Icons.lock
                            size: Theme.iconSizeXl
                            color: Theme.accent
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Locking in " + root.left + " s"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLarge
                            font.weight: Theme.weightBold
                            color: Theme.textPrimary
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "move the mouse or press a key to stay unlocked"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            color: Theme.textSecondary
                        }
                    }
                }
            }
        }
    }
}
