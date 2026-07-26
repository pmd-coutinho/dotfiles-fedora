pragma ComponentBehavior: Bound
// Shared scaffolding for the bar's drop-down menus (tray, audio, screen tools).
//
// ONE global window per menu that moves to the clicked widget's screen on open:
// a per-bar window nested in Bar.qml's Variants delegate ends up mapped on the
// wrong output. The full-screen transparent scrim below the bar catches outside
// clicks to dismiss, while the bar itself stays interactive because the window
// respects its exclusive zone.
//
// Children are placed in a Column inside the menu box, so they must size
// themselves vertically (`width: parent.width` is fine, `height: parent.height`
// is not — the box height comes from the content).
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Theme

PanelWindow {
    id: win

    default property alias content: inner.data

    property int boxWidth: 320
    // the bar widget this menu was opened from; also the "clicking it again
    // closes" token
    property var anchorSlot: null
    property real menuX: 0

    signal aboutToOpen

    function openFor(item, scr) {
        if (visible && anchorSlot === item) {
            close();
            return;
        }
        aboutToOpen();
        screen = scr;
        const centerX = Theme.barMarginSide + item.mapToItem(null, item.width / 2, 0).x;
        menuX = Math.min(Math.max(8, centerX - boxWidth / 2), scr.width - boxWidth - 8);
        anchorSlot = item;
        visible = true;
    }

    function close() {
        visible = false;
        anchorSlot = null;
    }

    visible: false
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"

    MouseArea {
        anchors.fill: parent
        onClicked: win.close()
    }

    Rectangle {
        x: win.menuX
        y: 4
        width: win.boxWidth
        height: inner.implicitHeight + 12
        radius: Theme.islandRadius
        color: Theme.alpha(Theme.mantle, 0.98)
        border.width: 1
        border.color: Theme.surface0

        Column {
            id: inner
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 6
        }
    }
}
