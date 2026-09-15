pragma Singleton
// Cross-component references: widgets living inside per-screen Variants
// delegates reach shell-level windows (menus, the control center, the OSD)
// through here. Assigned in shell.qml's Component.onCompleted, so every read is
// `Bus.x?.…` — the first binding evaluation can run before the assignment.
import QtQuick
import Quickshell

Singleton {
    property var trayMenu: null
    property var audioMenu: null
    property var screenToolsMenu: null
    property var calendarMenu: null
    // ControlCenter/ControlCenter.qml — open(page) with "controls" | "notifications"
    // | "wifi" | "bluetooth" | "audio" | "power"
    property var controlCenter: null
    property var sessionMenu: null
    // Osd/Osd.qml — show(kind, payload)
    property var osd: null
}
