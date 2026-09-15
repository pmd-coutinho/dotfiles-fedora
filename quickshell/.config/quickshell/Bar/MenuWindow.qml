pragma ComponentBehavior: Bound
// Shared scaffolding for the bar's drop-down menus (tray, audio, screen tools,
// calendar).
//
// ONE global window per menu that moves to the clicked widget's screen on open:
// a per-bar window nested in Bar.qml's Variants delegate ends up mapped on the
// wrong output. The full-screen transparent scrim below the bar catches outside
// clicks to dismiss, while the bar itself stays interactive because the window
// respects its exclusive zone. Esc closes too — the window takes keyboard focus
// only while `shown`, and stays mapped through the fade-out.
//
// Children are placed in a Column inside a Flickable, so they must size
// themselves vertically (`width: parent.width` is fine, `height: parent.height`
// is not — the box height comes from the content, capped to the screen).
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Components
import qs.Theme

PanelWindow {
    id: win

    default property alias content: inner.data

    property int boxWidth: Theme.menuWidth
    property bool shown: false
    // the bar widget this menu was opened from; also the "clicking it again
    // closes" token
    property var anchorSlot: null
    property real menuX: 0

    signal aboutToOpen

    function isOpenFor(item) {
        return shown && anchorSlot === item;
    }

    function openFor(item, scr) {
        if (isOpenFor(item)) {
            close();
            return;
        }
        aboutToOpen();
        screen = scr;
        const centerX = Theme.barMarginSide + item.mapToItem(null, item.width / 2, 0).x;
        menuX = Math.min(Math.max(Theme.spacingSm, centerX - boxWidth / 2), scr.width - boxWidth - Theme.spacingSm);
        anchorSlot = item;
        shown = true;
    }

    function close() {
        shown = false;
        anchorSlot = null;
    }

    // mapped while open and until the close animation finishes
    visible: shown || fade.running
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-menu"
    // modal while open; released during the fade-out so focus returns at once
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: win.close()

        MouseArea {
            anchors.fill: parent
            onClicked: win.close()
        }

        Surface {
            id: box

            elevation: 2
            color: Theme.surfaceOverlay
            x: win.menuX
            y: Theme.spacingXs
            width: win.boxWidth
            height: flick.height + 2 * Theme.menuPad
            opacity: win.shown ? 1 : 0
            transform: Translate {
                y: win.shown ? 0 : -8
                Behavior on y {
                    NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easeStandard }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    id: fade
                    duration: Theme.durationMedium
                    easing.type: Theme.easeStandard
                }
            }

            Flickable {
                id: flick
                x: Theme.menuPad
                y: Theme.menuPad
                width: parent.width - 2 * Theme.menuPad
                contentWidth: width
                contentHeight: inner.implicitHeight
                height: Math.min(contentHeight, win.height - box.y - 2 * Theme.menuPad - Theme.spacingXl)
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: inner
                    width: parent.width
                }
            }
        }
    }
}
