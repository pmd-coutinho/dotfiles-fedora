pragma ComponentBehavior: Bound
// Bluetooth devices through Quickshell.Bluetooth (bluez): adapter power,
// discoverable, scan while the page is open, connect / disconnect / pair /
// trust / forget, device battery. The binding has no pairing AGENT, so a device
// that wants a passkey confirmed (keyboards, some phones) still needs
// blueman — hence the "Advanced" row at the bottom. Headsets and mice pair
// fine from here.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.Components
import qs.Theme

Page {
    id: page

    title: "Bluetooth"

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property var devs: Bluetooth.devices.values
    readonly property var connected: devs.filter(d => d.state === BluetoothDeviceState.Connected || d.state === BluetoothDeviceState.Disconnecting)
    readonly property var paired: devs.filter(d => d.paired && !connected.includes(d))
    // hide address-only noise
    readonly property var available: devs.filter(d => !d.paired && (d.deviceName !== "" || d.name !== ""))
    property string openAddress: ""

    function startScan() {
        if (adapter && adapter.enabled && !adapter.discovering)
            adapter.discovering = true;
    }

    Component.onCompleted: startScan()
    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

    Connections {
        target: page.adapter
        function onEnabledChanged() {
            if (page.adapter.enabled)
                page.startScan();
        }
    }

    // ── header ──
    Rectangle {
        width: parent.width
        implicitHeight: 44
        radius: Theme.radiusMedium
        color: Theme.surfaceRaised

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingMd
            anchors.rightMargin: Theme.spacingSm
            spacing: Theme.spacingSm

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "Bluetooth"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    font.weight: Theme.weightBold
                    color: Theme.textPrimary
                }
                Text {
                    text: page.adapter === null ? "no adapter"
                        : page.adapter.state === BluetoothAdapterState.Blocked ? "blocked (rfkill)"
                        : page.adapter.state === BluetoothAdapterState.Enabling ? "turning on…"
                        : !page.on ? "off"
                        : page.adapter.discovering ? "scanning…"
                        : "on"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.textHint
                }
            }

            Button {
                compact: true
                glyph: Icons.refresh
                enabled: page.on
                onClicked: {
                    if (!page.adapter)
                        return;
                    page.adapter.discovering = false;
                    page.adapter.discovering = true;
                }
            }

            ToggleSwitch {
                checked: page.on
                switchEnabled: page.adapter !== null
                onToggled: if (page.adapter) page.adapter.enabled = !page.adapter.enabled
            }
        }
    }

    MenuRow {
        visible: page.on
        glyph: Icons.eye
        glyphColor: Theme.textMuted
        label: "Discoverable"
        sublabel: (page.adapter?.discoverable ?? false) ? "visible to other devices" : "hidden"
        onTriggered: {
            if (!page.adapter)
                return;
            if (!page.adapter.discoverable)
                page.adapter.discoverableTimeout = 120;
            page.adapter.discoverable = !page.adapter.discoverable;
        }

        ToggleSwitch {
            checked: page.adapter?.discoverable ?? false
            onToggled: {
                if (!page.adapter)
                    return;
                if (!page.adapter.discoverable)
                    page.adapter.discoverableTimeout = 120;
                page.adapter.discoverable = !page.adapter.discoverable;
            }
        }
    }

    component DeviceList: Column {
        id: section
        property string heading: ""
        property var devices: []
        width: parent.width
        visible: devices.length > 0 && page.on

        SectionHeader { text: section.heading }

        Repeater {
            model: ScriptModel {
                objectProp: "address"
                values: section.devices
            }

            Column {
                id: row

                required property var modelData
                readonly property var dev: modelData
                readonly property bool expanded: page.openAddress === dev.address
                readonly property string themed: Quickshell.iconPath(dev.icon, true)
                readonly property bool isConnected: dev.state === BluetoothDeviceState.Connected
                readonly property bool busy: dev.state === BluetoothDeviceState.Connecting
                                          || dev.state === BluetoothDeviceState.Disconnecting
                                          || dev.pairing
                property bool attempted: false
                property string error: ""

                width: parent.width

                function connectDev() {
                    row.error = "";
                    row.attempted = true;
                    row.dev.connect();
                }

                function pairDev() {
                    row.error = "";
                    row.attempted = true;
                    row.dev.pair();
                }

                Connections {
                    target: row.dev
                    function onPairedChanged() {
                        if (row.dev.paired && row.attempted) {
                            row.dev.trusted = true;
                            row.dev.connect();
                        }
                    }
                    function onStateChanged() {
                        if (row.dev.state === BluetoothDeviceState.Connected) {
                            row.error = "";
                            row.attempted = false;
                            page.openAddress = "";
                        } else if (row.attempted && row.dev.state === BluetoothDeviceState.Disconnected && !row.dev.pairing) {
                            row.error = "couldn't connect";
                            row.attempted = false;
                        }
                    }
                }

                MenuRow {
                    icon: row.themed
                    glyph: row.themed === "" ? Icons.bluetoothDevice(row.dev.icon) : ""
                    glyphColor: row.isConnected ? Theme.blue : Theme.textSecondary
                    label: row.dev.name || row.dev.deviceName || row.dev.address
                    selected: row.isConnected
                    sublabel: row.error !== "" ? row.error
                            : row.dev.pairing ? "pairing…"
                            : row.dev.state === BluetoothDeviceState.Connecting ? "connecting…"
                            : row.dev.state === BluetoothDeviceState.Disconnecting ? "disconnecting…"
                            : row.isConnected && row.dev.batteryAvailable ? "connected · " + Math.round(row.dev.battery * 100) + "%"
                            : row.isConnected ? "connected"
                            : row.dev.paired ? "paired"
                            : ""
                    busy: row.busy
                    hasSubmenu: !row.busy
                    onTriggered: {
                        if (row.expanded) {
                            page.openAddress = "";
                            return;
                        }
                        if (!row.dev.paired && !row.isConnected) {
                            row.pairDev();
                            return;
                        }
                        page.openAddress = row.dev.address;
                    }
                }

                Item {
                    width: parent.width
                    height: row.expanded ? actions.implicitHeight + Theme.spacingSm : 0
                    clip: true

                    Behavior on height {
                        NumberAnimation { duration: Theme.durationShort; easing.type: Theme.easeStandard }
                    }

                    Flow {
                        id: actions
                        x: Theme.spacingXl
                        width: parent.width - Theme.spacingXl - Theme.spacingSm
                        spacing: Theme.spacingXs

                        Button {
                            compact: true
                            kind: row.isConnected ? "ghost" : "primary"
                            text: row.isConnected ? "disconnect" : "connect"
                            enabled: !row.busy
                            onClicked: row.isConnected ? row.dev.disconnect() : row.connectDev()
                        }
                        Button {
                            visible: row.dev.pairing
                            compact: true
                            text: "cancel pairing"
                            onClicked: row.dev.cancelPair()
                        }
                        Button {
                            compact: true
                            text: row.dev.trusted ? "trusted" : "trust"
                            glyph: row.dev.trusted ? Icons.check : ""
                            onClicked: row.dev.trusted = !row.dev.trusted
                        }
                        Button {
                            compact: true
                            kind: "danger"
                            text: "forget"
                            onClicked: {
                                page.openAddress = "";
                                row.dev.forget();
                            }
                        }
                    }
                }
            }
        }
    }

    DeviceList { heading: "connected"; devices: page.connected }
    DeviceList { heading: "paired"; devices: page.paired }
    DeviceList { heading: "available"; devices: page.available }

    Text {
        visible: page.on && page.devs.length === 0
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: Theme.spacingLg
        text: "no devices yet"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontLabel
        color: Theme.textMuted
    }

    Item { width: 1; height: Theme.spacingSm }

    MenuRow {
        glyph: Icons.settings
        glyphColor: Theme.textMuted
        label: "Advanced (blueman)…"
        sublabel: "passkey pairing, audio profiles"
        onTriggered: Quickshell.execDetached(["blueman-manager"])
    }
}
