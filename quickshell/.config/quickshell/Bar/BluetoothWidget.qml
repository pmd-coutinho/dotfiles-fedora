// Bluetooth adapter + connected devices via native bluez. Click opens the
// control center's bluetooth page, right-click toggles the adapter power.
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    // Deliberately NOT called `enabled`: that would shadow Item.enabled and
    // disable the MouseArea that right-click-to-power-on depends on.
    readonly property bool adapterOn: adapter?.enabled ?? false
    readonly property var connectedDevs: Bluetooth.devices.values.filter(d => d.connected)
    readonly property var battDev: connectedDevs.find(d => d.batteryAvailable) ?? null

    tip: {
        if (!adapterOn)
            return "bluetooth off";
        if (connectedDevs.length === 0)
            return "bluetooth on";
        return connectedDevs
            .map(d => d.batteryAvailable ? d.name + " " + Math.round(d.battery * 100) + "%" : d.name)
            .join(" · ");
    }
    hint: "click: devices · right: " + (adapterOn ? "turn off" : "turn on")

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: !root.adapterOn ? Icons.bluetoothOff
             : root.connectedDevs.length > 0 ? Icons.bluetoothConnected
             : Icons.bluetooth
        color: root.adapterOn ? Theme.blue : Theme.textMuted
    }

    Badge {
        anchors.verticalCenter: parent.verticalCenter
        count: root.adapterOn ? root.connectedDevs.length : 0
        fill: Theme.blue
    }

    onClicked: button => {
        if (button === Qt.LeftButton) {
            if (Bus.controlCenter)
                Bus.controlCenter.open("bluetooth");
            else
                Quickshell.execDetached(["blueman-manager"]);
        } else if (button === Qt.RightButton && adapter) {
            adapter.enabled = !adapter.enabled;
        }
    }
}
