pragma ComponentBehavior: Bound
// QML-rendered tray context menu — platform menus under Qt come up unthemed and
// mispositioned on niri, so the entries are drawn here from the item's DBus menu
// and submenus navigate with a back row.
//
// Window placement, the dismiss scrim and the menu box come from MenuWindow.qml.
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Theme

MenuWindow {
    id: menuWin

    property var rootHandle: null
    // submenu navigation stack of QsMenuEntry handles
    property var stack: []

    boxWidth: 240

    // Not called openFor: that would shadow MenuWindow's and recurse. Callers
    // use this, which records the handle and delegates placement to the base.
    function openMenu(item, handle, scr) {
        rootHandle = handle;
        stack = [];
        openFor(item, scr);
    }

    // dropping the handle on close matters — it holds the app's DBus menu open
    onVisibleChanged: {
        if (!visible) {
            rootHandle = null;
            stack = [];
        }
    }

    QsMenuOpener {
        id: opener
        menu: menuWin.stack.length > 0 ? menuWin.stack[menuWin.stack.length - 1] : menuWin.rootHandle
    }


    // back row while inside a submenu
    Rectangle {
        visible: menuWin.stack.length > 0
        width: parent.width
        height: 28
        radius: Theme.radiusSmall
        color: backArea.containsMouse ? Theme.surface0 : "transparent"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 8
            text: "󰅁 back"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
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
            radius: Theme.radiusSmall
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
                spacing: Theme.spacingSm

                Text {
                    visible: row.modelData.buttonType !== 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.checkState === Qt.Checked ? Icons.checked : Icons.unchecked
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
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
                    font.pixelSize: Theme.fontLabel
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
                font.pixelSize: Theme.fontLabel
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
