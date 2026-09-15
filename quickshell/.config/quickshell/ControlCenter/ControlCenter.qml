pragma ComponentBehavior: Bound
// The control center: one drawer on the right edge with two tabs — Controls
// (sliders, quick toggles, media) and Notifications (history) — and sub-pages
// for wifi / bluetooth / audio / do-not-disturb / power. Replaces the swaync-
// shaped Notifications/Panel.qml.
//
// ONE global window that moves to the screen captured at open (a per-screen
// Variants would keep three windows mounted for nothing). `Notifs.panelOpen`
// is the intent (persisted, driven by the bell and `qs ipc call notifs
// toggle`); `mounted` is whether the layer surface exists; `shown` drives the
// slide/fade. A layer-shell window can't animate `visible`, so the drawer
// slides in one frame after the surface maps and the surface unmaps one
// animation after the drawer has slid out.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Components
import qs.Services
import qs.Theme

Scope {
    id: root

    property bool mounted: false
    property bool shown: false
    property var screenAtOpen: null
    property string requestedTab: "controls"
    property string requestedPage: ""

    readonly property var pageComponents: ({
        wifi: wifiPage,
        bluetooth: bluetoothPage,
        audio: audioPage,
        dnd: dndPage,
        power: powerPage
    })

    // page: "controls" | "notifications" | "wifi" | "bluetooth" | "audio" | "dnd" | "power"
    function open(page) {
        const tab = page === "notifications" ? "notifications" : "controls";
        const sub = pageComponents[page] ? page : "";
        if (Notifs.panelOpen && mounted) {
            show(tab, sub, false);
            return;
        }
        requestedTab = tab;
        requestedPage = sub;
        Notifs.panelOpen = true;
    }

    function toggle() {
        Notifs.panelOpen = !Notifs.panelOpen;
    }

    function close() {
        Notifs.panelOpen = false;
    }

    // navigate inside an open drawer
    function push(name) {
        const c = pageComponents[name];
        if (c)
            nav.push(c);
    }

    function show(tab, sub, immediate) {
        home.tab = tab;
        nav.pop(null, StackView.Immediate);
        if (sub !== "")
            nav.push(pageComponents[sub], immediate ? StackView.Immediate : StackView.PushTransition);
    }

    Connections {
        target: Notifs
        function onPanelOpenChanged() {
            if (Notifs.panelOpen) {
                unmount.stop();
                if (!root.mounted) {
                    root.screenAtOpen = Niri.focusedScreen;
                    root.mounted = true;
                }
                arm.restart();
            } else {
                arm.stop();
                root.shown = false;
                unmount.restart();
            }
        }
    }

    // the drawer state survives a hot reload (panelOpen is persisted)
    Component.onCompleted: {
        if (Notifs.panelOpen) {
            root.screenAtOpen = Niri.focusedScreen;
            root.mounted = true;
            arm.restart();
        }
    }

    // let the surface map, then slide in
    Timer {
        id: arm
        interval: 16
        onTriggered: {
            root.show(root.requestedTab, root.requestedPage, true);
            root.requestedTab = "controls";
            root.requestedPage = "";
            root.shown = true;
        }
    }

    Timer {
        id: unmount
        interval: Theme.durationMedium + 40
        onTriggered: {
            if (Notifs.panelOpen)
                return;
            root.mounted = false;
            nav.pop(null, StackView.Immediate);
            home.tab = "controls";
        }
    }

    Component { id: wifiPage; WifiPage {} }
    Component { id: bluetoothPage; BluetoothPage {} }
    Component { id: audioPage; AudioPage {} }
    Component { id: dndPage; DndPage {} }
    Component { id: powerPage; PowerPage {} }

    PanelWindow {
        id: win

        screen: root.screenAtOpen ?? Niri.focusedScreen
        visible: root.mounted
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        // sits below the bar's exclusive zone: the bell stays clickable
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-controlcenter"
        // Esc, and the wifi password field, need the keyboard
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Theme.scrimLight
            opacity: root.shown ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.durationMedium }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Notifs.panelOpen = false
            }
        }

        FocusScope {
            anchors.fill: parent
            focus: true

            Keys.onEscapePressed: {
                if (nav.depth > 1)
                    nav.pop();
                else
                    Notifs.panelOpen = false;
            }

            Surface {
                id: drawer

                elevation: 2
                width: Theme.panelWidth
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                    topMargin: Theme.spacingSm
                    bottomMargin: Theme.spacingSm + Theme.shadowOffset2
                    rightMargin: root.shown ? Theme.barMarginSide : -(width + Theme.shadowBlur2 + Theme.spacingLg)
                }
                opacity: root.shown ? 1 : 0

                Behavior on anchors.rightMargin {
                    NumberAnimation {
                        duration: Theme.durationMedium
                        easing.type: root.shown ? Theme.easeStandard : Theme.easeExit
                    }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.durationShort }
                }

                // swallow clicks so they don't reach the scrim
                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMd
                    spacing: Theme.spacingSm

                    // ── top bar: back · title · close ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSm

                        Button {
                            visible: nav.depth > 1
                            compact: true
                            glyph: Icons.back
                            onClicked: nav.pop()
                        }

                        Text {
                            Layout.fillWidth: true
                            text: nav.currentItem?.title ?? ""
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLarge
                            font.weight: Theme.weightBold
                            color: Theme.textPrimary
                        }

                        Button {
                            compact: true
                            glyph: Icons.close
                            onClicked: Notifs.panelOpen = false
                        }
                    }

                    StackView {
                        id: nav
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        initialItem: home

                        pushEnter: Transition {
                            NumberAnimation { property: "x"; from: nav.width * 0.3; to: 0; duration: Theme.durationMedium; easing.type: Theme.easeStandard }
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationMedium }
                        }
                        pushExit: Transition {
                            NumberAnimation { property: "x"; from: 0; to: -nav.width * 0.3; duration: Theme.durationMedium; easing.type: Theme.easeStandard }
                            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationMedium }
                        }
                        popEnter: Transition {
                            NumberAnimation { property: "x"; from: -nav.width * 0.3; to: 0; duration: Theme.durationMedium; easing.type: Theme.easeStandard }
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationMedium }
                        }
                        popExit: Transition {
                            NumberAnimation { property: "x"; from: 0; to: nav.width * 0.3; duration: Theme.durationMedium; easing.type: Theme.easeStandard }
                            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationMedium }
                        }
                    }
                }
            }

            // StackView reparents this into itself as the root page
            HomePage {
                id: home
                visible: false
            }
        }
    }
}
