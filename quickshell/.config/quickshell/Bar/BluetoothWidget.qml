// Bluetooth adapter + connected devices via native bluez. Click opens
// blueman-manager, right-click toggles the adapter power.
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.Theme

BarText {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    // Deliberately NOT called `enabled`: that shadows Item.enabled on the
    // underlying Text, which at best confuses readers and at worst disables the
    // MouseArea that right-click-to-power-on depends on — i.e. exactly when the
    // adapter is off and you need that click. (qmllint property-override.)
    readonly property bool adapterOn: adapter?.enabled ?? false
    readonly property var connectedDevs: Bluetooth.devices.values.filter(d => d.connected)
    readonly property var battDev: connectedDevs.find(d => d.batteryAvailable) ?? null

    text: !adapterOn ? "󰂲"
        : connectedDevs.length === 0 ? ""
        : battDev ? " " + Math.round(battDev.battery * 100) + "%"
        : " " + connectedDevs.length
    color: adapterOn ? Theme.blue : Theme.overlay0

    tip: {
        const name = adapter?.name ?? "bluetooth";
        if (!adapterOn)
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
