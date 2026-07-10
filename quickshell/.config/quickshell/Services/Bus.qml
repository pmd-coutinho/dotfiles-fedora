pragma Singleton
// Cross-component references: widgets living inside per-screen Variants
// delegates reach shell-level windows (like the tray menu) through here.
import QtQuick
import Quickshell

Singleton {
    property var trayMenu: null
}
