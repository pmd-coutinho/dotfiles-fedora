pragma ComponentBehavior: Bound
// QML-rendered tray context menu — platform menus under Qt come up unthemed and
// mispositioned on niri, so the entries are drawn here from the item's DBus menu
// and submenus navigate with a back row.
//
// Window placement, the dismiss scrim and the menu box come from MenuWindow.qml.
import QtQuick
import Quickshell
import qs.Components
import qs.Theme

MenuWindow {
    id: menuWin

    property var rootHandle: null
    // submenu navigation stack of QsMenuEntry handles
    property var stack: []

    boxWidth: Theme.menuWidthNarrow

    // Not called openFor: that would shadow MenuWindow's and recurse. Callers
    // use this, which records the handle and delegates placement to the base.
    function openMenu(item, handle, scr) {
        rootHandle = handle;
        stack = [];
        openFor(item, scr);
    }

    // dropping the handle on close matters — it holds the app's DBus menu open
    onShownChanged: {
        if (!shown) {
            rootHandle = null;
            stack = [];
        }
    }

    QsMenuOpener {
        id: opener
        menu: menuWin.stack.length > 0 ? menuWin.stack[menuWin.stack.length - 1] : menuWin.rootHandle
    }

    // back row while inside a submenu
    MenuRow {
        visible: menuWin.stack.length > 0
        glyph: Icons.chevronLeft
        glyphColor: Theme.textMuted
        label: "back"
        onTriggered: menuWin.stack = menuWin.stack.slice(0, -1)
    }

    Repeater {
        model: opener.children

        Column {
            id: entry

            required property var modelData
            readonly property bool isSep: modelData.isSeparator

            width: parent.width

            MenuSeparator {
                visible: entry.isSep
            }

            MenuRow {
                visible: !entry.isSep
                icon: entry.modelData.icon
                label: entry.modelData.text
                checkable: entry.modelData.buttonType !== 0
                checked: entry.modelData.checkState === Qt.Checked
                selected: checked
                hasSubmenu: entry.modelData.hasChildren
                rowEnabled: entry.modelData.enabled
                onTriggered: {
                    if (entry.modelData.hasChildren) {
                        menuWin.stack = menuWin.stack.concat([entry.modelData]);
                    } else {
                        entry.modelData.triggered();
                        menuWin.close();
                    }
                }
            }
        }
    }
}
