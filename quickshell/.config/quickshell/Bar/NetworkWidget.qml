// Network status via native NetworkManager. Click opens the control center's
// wifi page, right-click toggles wifi.
import QtQuick
import Quickshell
import Quickshell.Networking
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var wifiNet: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property int signal: {
        const s = wifiNet?.signalStrength ?? 0;
        return Math.round(s <= 1 ? s * 100 : s);
    }
    readonly property bool online: wired !== null || wifi !== null

    tip: wired ? wired.name + " · " + wired.address
       : wifi ? (wifiNet?.name ?? wifi.name) + " · " + signal + "% · " + wifi.address
       : Networking.wifiEnabled ? "disconnected" : "wifi off"
    hint: "click: networks · right: wifi " + (Networking.wifiEnabled ? "off" : "on")

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.wired ? Icons.wired
             : root.wifi ? Icons.wifi(root.signal)
             : Networking.wifiEnabled ? Icons.wifiOff
             : Icons.wifiDisabled
        color: root.online ? Theme.success : Theme.textMuted
    }

    onClicked: button => {
        if (button === Qt.LeftButton) {
            if (Bus.controlCenter)
                Bus.controlCenter.open("wifi");
            else
                Quickshell.execDetached(["nm-connection-editor"]);
        } else if (button === Qt.RightButton) {
            Networking.wifiEnabled = !Networking.wifiEnabled;
        }
    }
}
