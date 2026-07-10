pragma ComponentBehavior: Bound
// QML-rendered tray context menu — platform menus under Qt come up unthemed
// and mispositioned on niri. ONE global window that jumps to the clicked
// icon's screen on open (a persistent per-bar window nested in the Variants
// delegate mapped on the wrong output). The transparent overlay below the
// bar catches outside clicks to dismiss; submenus navigate with a back row.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Theme

PanelWindow {
    id: menuWin

    property var rootHandle: null
    property var anchorSlot: null
    // submenu navigation stack of QsMenuEntry handles
    property var stack: []
    property real menuX: 0

    function openFor(item, handle, scr) {
        // clicking the same tray icon again closes the menu
        if (visible && anchorSlot === item) {
            close();
            return;
        }
        screen = scr;
        const centerX = Theme.barMarginSide + item.mapToItem(null, item.width / 2, 0).x;
        menuX = Math.min(Math.max(8, centerX - 120), scr.width - 248);
        anchorSlot = item;
        rootHandle = handle;
        stack = [];
        visible = true;
    }

    function close() {
        visible = false;
        anchorSlot = null;
        rootHandle = null;
        stack = [];
    }

    visible: false
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    margins {
        // start below the bar so the bar itself stays interactive
        top: Theme.barHeight + Theme.barMarginTop * 2
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"

    // click anywhere outside the menu box dismisses it
    MouseArea {
        anchors.fill: parent
        onClicked: menuWin.close()
    }

    QsMenuOpener {
        id: opener
        menu: menuWin.stack.length > 0 ? menuWin.stack[menuWin.stack.length - 1] : menuWin.rootHandle
    }

    Rectangle {
        id: box
        x: menuWin.menuX
        y: 4
        width: 240
        height: list.implicitHeight + 12
        radius: Theme.islandRadius
        color: Theme.alpha(Theme.mantle, 0.98)
        border.width: 1
        border.color: Theme.surface0

        Column {
            id: list
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 6

            // back row while inside a submenu
            Rectangle {
                visible: menuWin.stack.length > 0
                width: parent.width
                height: 28
                radius: 6
                color: backArea.containsMouse ? Theme.surface0 : "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 8
                    text: "󰅁 back"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    color: Theme.subtext0
                }
                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: menuWin.stack = menuWin.stack.slice(0, -1)
                }
            }

            Repeater {
                model: opener.children

                Rectangle {
                    id: row

                    required property var modelData
                    readonly property bool isSep: modelData.isSeparator

                    width: parent.width
                    height: isSep ? 9 : 28
                    radius: 6
                    color: !isSep && rowArea.containsMouse && modelData.enabled
                        ? Theme.surface0 : "transparent"

                    Rectangle {
                        visible: row.isSep
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 16
                        x: 8
                        height: 1
                        color: Theme.surface0
                    }

                    Row {
                        visible: !row.isSep
                        anchors.verticalCenter: parent.verticalCenter
                        x: 8
                        spacing: 8

                        Text {
                            visible: row.modelData.buttonType !== 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.checkState === Qt.Checked ? "󰄲" : "󰄱"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: row.modelData.checkState === Qt.Checked ? Theme.mauve : Theme.overlay0
                        }

                        IconImage {
                            visible: row.modelData.icon !== ""
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            source: row.modelData.icon
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: row.modelData.enabled ? Theme.text : Theme.overlay0
                        }
                    }

                    Text {
                        visible: !row.isSep && row.modelData.hasChildren
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅂"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 1
                        color: Theme.overlay0
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !row.isSep
                        onClicked: {
                            if (!row.modelData.enabled)
                                return;
                            if (row.modelData.hasChildren) {
                                menuWin.stack = menuWin.stack.concat([row.modelData]);
                            } else {
                                row.modelData.triggered();
                                menuWin.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
