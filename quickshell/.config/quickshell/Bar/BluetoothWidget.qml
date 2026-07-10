// Bluetooth adapter + connected devices via native bluez. Click opens
// blueman-manager, right-click toggles the adapter power.
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.Theme

BarText {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connectedDevs: Bluetooth.devices.values.filter(d => d.connected)
    readonly property var battDev: connectedDevs.find(d => d.batteryAvailable) ?? null

    text: !enabled ? "󰂲"
        : connectedDevs.length === 0 ? ""
        : battDev ? " " + Math.round(battDev.battery * 100) + "%"
        : " " + connectedDevs.length
    color: enabled ? Theme.blue : Theme.overlay0

    tip: {
        const name = adapter?.name ?? "bluetooth";
        if (!enabled)
            return name + "\noff";
        if (connectedDevs.length === 0)
            return name + "\non";
        const devs = connectedDevs
            .map(d => d.batteryAvailable
                ? d.name + " — " + Math.round(d.battery * 100) + "%"
                : d.name + " (" + d.address + ")")
            .join("\n");
        return name + "\n" + connectedDevs.length + " connected\n\n" + devs;
    }

    onModuleClicked: button => {
        if (button === Qt.LeftButton)
            Quickshell.execDetached(["blueman-manager"]);
        else if (button === Qt.RightButton && adapter)
            adapter.enabled = !adapter.enabled;
    }
}
