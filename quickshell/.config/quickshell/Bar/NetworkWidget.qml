// Network status via native NetworkManager backend. Click opens
// nm-connection-editor.
import QtQuick
import Quickshell
import Quickshell.Networking
import qs.Theme

BarText {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var wifiNet: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property int signal: {
        const s = wifiNet?.signalStrength ?? 0;
        return Math.round(s <= 1 ? s * 100 : s);
    }

    text: wired ? "󰈀"
        : wifi ? "  " + signal + "%"
        : "󰖪"
    color: (wired || wifi) ? Theme.green : Theme.overlay0

    tip: wired ? wired.name + " · " + wired.address
       : wifi ? (wifiNet?.name ?? wifi.name) + " · " + wifi.address
       : "disconnected"

    onModuleClicked: button => {
        if (button === Qt.LeftButton)
            Quickshell.execDetached(["nm-connection-editor"]);
    }
}
