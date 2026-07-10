// Notification bell — Phase 1 placeholder bridging swaync (subscribes via
// swaync-client -swb, same as the old waybar module). Becomes native state
// once quickshell owns notifications in Phase 2.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Theme

BarText {
    id: root

    property string alt: "none"

    readonly property var icons: ({
        "notification": "󱅫",
        "none": "󰂚",
        "dnd-notification": "󰂛",
        "dnd-none": "󰂛",
        "inhibited-notification": "󱅫",
        "inhibited-none": "󰂚",
        "dnd-inhibited-notification": "󰂛",
        "dnd-inhibited-none": "󰂛"
    })

    text: icons[alt] ?? "󰂚"
    color: Theme.mauve
    font.pixelSize: Theme.fontSize + 1
    rightPadding: 14

    onModuleClicked: button => {
        if (button === Qt.LeftButton)
            Quickshell.execDetached(["swaync-client", "-t", "-sw"]);
        else if (button === Qt.RightButton)
            Quickshell.execDetached(["swaync-client", "-d", "-sw"]);
    }

    Process {
        id: sub
        command: ["swaync-client", "-swb"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.alt = JSON.parse(line).alt ?? "none";
                } catch (e) {}
            }
        }
        // swaync may not be up yet at login; retry the subscription
        onExited: retry.start()
    }

    Timer {
        id: retry
        interval: 3000
        onTriggered: sub.running = true
    }
}
