pragma ComponentBehavior: Bound
// Session menu: lock / logout / suspend / reboot / poweroff. Toggled via
// `qs ipc call session toggle` (Mod+Shift+E) and the control center's power
// button.
//
// Every output is scrimmed while it is open (a modal that leaves two monitors
// fully interactive isn't one); the tiles sit on the output that had focus at
// open. Fully keyboard-driven: ←/→/Tab move, Enter activates, l/o/s/r/p jump,
// Esc cancels. Logout, reboot and poweroff ask for a second press within
// three seconds — one misclick between two adjacent 112px tiles used to be
// `systemctl poweroff` with no way back.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.Components
import qs.Services
import qs.Theme

Scope {
    id: root

    property bool open: false
    property bool mounted: false        // survives the close animation
    property var targetScreen: null     // captured on open so the tiles don't jump
    property int cursor: 0
    property int pending: -1            // tile awaiting confirmation
    property int pendingLeft: 0

    readonly property var actions: [
        { key: "l", icon: Icons.lock, label: "lock", danger: false, run: () => Session.lock() },
        { key: "o", icon: Icons.logout, label: "logout", danger: true, run: () => Session.logout() },
        { key: "s", icon: Icons.suspend, label: "suspend", danger: false, run: () => Session.suspend() },
        { key: "r", icon: Icons.reboot, label: "reboot", danger: true, run: () => Session.reboot() },
        { key: "p", icon: Icons.poweroff, label: "power off", danger: true, run: () => Session.poweroff() }
    ]

    function toggle() {
        if (open)
            close();
        else
            show();
    }

    function show() {
        targetScreen = Niri.focusedScreen;
        cursor = 0;
        cancelPending();
        User.refreshUptime();
        closeTimer.stop();
        mounted = true;
        open = true;
    }

    function close() {
        open = false;
        cancelPending();
        closeTimer.restart();
    }

    function move(d) {
        cursor = (cursor + d + actions.length) % actions.length;
        if (pending >= 0 && pending !== cursor)
            cancelPending();
    }

    function activate(i) {
        const a = actions[i];
        if (!a.danger || pending === i) {
            run(a);
            return;
        }
        pending = i;
        pendingLeft = 3;
        confirmTick.restart();
    }

    function cancelPending() {
        pending = -1;
        confirmTick.stop();
    }

    function run(a) {
        close();
        // let the scrim start fading before the action lands
        Qt.callLater(a.run);
    }

    Timer {
        id: closeTimer
        interval: Theme.durationMedium + 50
        onTriggered: if (!root.open) root.mounted = false
    }

    Timer {
        id: confirmTick
        interval: 1000
        repeat: true
        onTriggered: {
            if (--root.pendingLeft <= 0)
                root.cancelPending();
        }
    }

    component SessionTile: Item {
        id: tile

        required property int index
        required property var modelData
        readonly property bool focused: root.cursor === index
        readonly property bool confirming: root.pending === index

        implicitWidth: 112
        implicitHeight: 112
        scale: root.open ? 1 : 0.9
        opacity: root.open ? 1 : 0

        Behavior on scale {
            SequentialAnimation {
                PauseAnimation { duration: root.open ? tile.index * 30 : 0 }
                NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easeStandard }
            }
        }
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: root.open ? tile.index * 30 : 0 }
                NumberAnimation { duration: Theme.durationMedium }
            }
        }

        Surface {
            anchors.fill: parent
            anchors.topMargin: tile.focused ? -4 : 0
            anchors.bottomMargin: tile.focused ? 4 : 0
            elevation: 2
            color: tile.confirming ? Theme.alpha(Theme.error, 0.18)
                 : tile.focused ? Theme.alpha(Theme.surface1, 0.96)
                 : Theme.surface
            borderColor: tile.confirming ? Theme.error
                       : tile.focused ? Theme.accent
                       : Theme.outline
            borderWidth: tile.focused || tile.confirming ? 2 : 1

            Behavior on anchors.topMargin {
                NumberAnimation { duration: Theme.durationShort; easing.type: Theme.easeStandard }
            }
            Behavior on anchors.bottomMargin {
                NumberAnimation { duration: Theme.durationShort; easing.type: Theme.easeStandard }
            }

            Column {
                anchors.centerIn: parent
                spacing: Theme.spacingSm

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    glyph: tile.confirming ? Icons.check : tile.modelData.icon
                    size: Theme.iconSizeXl
                    color: tile.confirming ? Theme.error
                         : tile.focused ? Theme.accent
                         : Theme.textPrimary
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tile.confirming ? "confirm? " + root.pendingLeft : tile.modelData.label
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    font.weight: tile.confirming ? Theme.weightBold : Theme.weightRegular
                    color: tile.confirming ? Theme.error : Theme.textSecondary
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.cursor = tile.index
                onClicked: root.activate(tile.index)
            }
        }
    }

    LazyLoader {
        active: root.mounted

        Variants {
            model: Quickshell.screens

            PanelWindow {
                id: win

                required property ShellScreen modelData
                readonly property bool primary: modelData === root.targetScreen

                screen: modelData
                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-session"
                WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    color: Theme.crust
                    opacity: root.open ? 0.6 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.durationMedium }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }

                Loader {
                    anchors.fill: parent
                    active: win.primary

                    sourceComponent: FocusScope {
                        focus: true
                        Component.onCompleted: forceActiveFocus()

                        Keys.onPressed: event => {
                            switch (event.key) {
                            case Qt.Key_Escape:
                                if (root.pending >= 0)
                                    root.cancelPending();
                                else
                                    root.close();
                                break;
                            case Qt.Key_Left:
                            case Qt.Key_Backtab:
                            case Qt.Key_H:
                                root.move(-1);
                                break;
                            case Qt.Key_Right:
                            case Qt.Key_Tab:
                                root.move(1);
                                break;
                            case Qt.Key_Home:
                                root.cursor = 0;
                                break;
                            case Qt.Key_End:
                                root.cursor = root.actions.length - 1;
                                break;
                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                            case Qt.Key_Space:
                                root.activate(root.cursor);
                                break;
                            default: {
                                const i = root.actions.findIndex(a => a.key === event.text.toLowerCase());
                                if (i < 0)
                                    return;
                                root.cursor = i;
                                root.activate(i);
                            }
                            }
                            event.accepted = true;
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXl

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: Theme.spacingLg

                                Repeater {
                                    model: root.actions
                                    SessionTile {}
                                }
                            }

                            // uptime · battery
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                readonly property var batt: UPower.displayDevice
                                text: [
                                    User.uptimeText,
                                    (batt?.isLaptopBattery ?? false) ? Math.round(batt.percentage * 100) + "% battery" : ""
                                ].filter(s => s !== "").join("  ·  ")
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                color: Theme.textHint
                                opacity: root.open ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: Theme.durationMedium }
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "← →  move   ·   enter  select   ·   l o s r p   ·   esc"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontTiny
                                color: Theme.textMuted
                                opacity: root.open ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: Theme.durationMedium }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
