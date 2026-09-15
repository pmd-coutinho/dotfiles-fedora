pragma ComponentBehavior: Bound
// Wi‑Fi networks, fully through Quickshell.Networking (NetworkManager):
// scan while the page is open, connect / connect-with-password / disconnect /
// forget. Only 802.1X (enterprise) networks still need nm-connection-editor —
// the binding has no path for those, so the row opens the editor.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs.Components
import qs.Theme

Page {
    id: page

    title: "Wi‑Fi"

    readonly property var dev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var nets: (dev?.networks.values ?? [])
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (sig(b) - sig(a)))
    // the row whose extra controls (password / disconnect) are open
    property string openName: ""

    function sig(n) {
        const s = n.signalStrength;
        return s <= 1 ? s * 100 : s;
    }

    function isEap(n) {
        return n.security === WifiSecurityType.Wpa2Eap || n.security === WifiSecurityType.WpaEap;
    }

    function isOpen(n) {
        return n.security === WifiSecurityType.Open || n.security === WifiSecurityType.Owe;
    }

    // scanning is page-scoped: leaving the page stops it
    Component.onCompleted: if (dev) dev.scannerEnabled = true
    Component.onDestruction: if (dev) dev.scannerEnabled = false

    function rescan() {
        if (!dev)
            return;
        dev.scannerEnabled = false;
        dev.scannerEnabled = true;
    }

    // ── header: switch · status · rescan ──
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
                    text: "Wi‑Fi"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    font.weight: Theme.weightBold
                    color: Theme.textPrimary
                }
                Text {
                    text: !Networking.wifiHardwareEnabled ? "hardware switch off"
                        : !Networking.wifiEnabled ? "off"
                        : page.dev === null ? "no wifi device"
                        : (page.dev.scannerEnabled ? "scanning…" : "on")
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.textHint
                }
            }

            Button {
                compact: true
                glyph: Icons.refresh
                enabled: Networking.wifiEnabled && page.dev !== null
                onClicked: page.rescan()
            }

            ToggleSwitch {
                checked: Networking.wifiEnabled
                switchEnabled: Networking.wifiHardwareEnabled
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }
    }

    // captive portal
    Rectangle {
        width: parent.width
        visible: Networking.connectivity === NetworkConnectivity.Portal
        implicitHeight: 36
        radius: Theme.radiusMedium
        color: Theme.alpha(Theme.warning, 0.15)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingMd
            anchors.rightMargin: Theme.spacingSm

            Icon { glyph: Icons.warning; color: Theme.warning }
            Text {
                Layout.fillWidth: true
                text: "sign-in required"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: Theme.textPrimary
            }
            Button {
                compact: true
                text: "open"
                onClicked: Quickshell.execDetached(["xdg-open", "http://nmcheck.gnome.org/"])
            }
        }
    }

    SectionHeader {
        visible: page.nets.length > 0
        text: "networks"
    }

    Text {
        visible: Networking.wifiEnabled && page.nets.length === 0
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: Theme.spacingLg
        text: "no networks found yet"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontLabel
        color: Theme.textMuted
    }

    Repeater {
        model: ScriptModel {
            objectProp: "name"
            values: page.nets
        }

        Column {
            id: row

            required property var modelData
            readonly property var net: modelData
            readonly property bool expanded: page.openName === net.name
            readonly property bool secured: !page.isOpen(net)
            property bool askPsk: false
            property string error: ""

            width: parent.width

            Connections {
                target: row.net
                function onConnectionFailed(reason) {
                    row.error = ({
                        [ConnectionFailReason.NoSecrets]: "password required",
                        [ConnectionFailReason.WifiAuthTimeout]: "wrong password or timeout",
                        [ConnectionFailReason.WifiNetworkLost]: "network lost"
                    })[reason] ?? ConnectionFailReason.toString(reason);
                    if (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout) {
                        // a saved-but-wrong PSK must be cleared before a retry prompts again
                        if (row.net.known)
                            row.net.forget();
                        row.askPsk = true;
                        page.openName = row.net.name;
                    }
                }
                function onConnectedChanged() {
                    if (row.net.connected) {
                        row.error = "";
                        row.askPsk = false;
                        page.openName = "";
                    }
                }
            }

            MenuRow {
                glyph: Icons.wifi(page.sig(row.net))
                glyphColor: row.net.connected ? Theme.success : Theme.textSecondary
                label: row.net.name
                selected: row.net.connected
                sublabel: row.error !== "" ? row.error
                        : row.net.connected ? "connected"
                        : row.net.stateChanging ? "connecting…"
                        : row.net.known ? "saved"
                        : page.isEap(row.net) ? "enterprise"
                        : ""
                detail: row.secured ? Icons.lock : ""
                busy: row.net.stateChanging
                onTriggered: {
                    row.error = "";
                    if (row.net.connected) {
                        page.openName = row.expanded ? "" : row.net.name;
                        row.askPsk = false;
                    } else if (page.isEap(row.net)) {
                        Quickshell.execDetached(["nm-connection-editor"]);
                    } else if (row.net.known || !row.secured) {
                        row.net.connect();
                    } else {
                        row.askPsk = true;
                        page.openName = row.net.name;
                    }
                }
            }

            // ── expanded controls ──
            Item {
                width: parent.width
                height: row.expanded ? extra.implicitHeight + Theme.spacingSm : 0
                clip: true

                Behavior on height {
                    NumberAnimation { duration: Theme.durationShort; easing.type: Theme.easeStandard }
                }

                ColumnLayout {
                    id: extra
                    x: Theme.spacingXl
                    width: parent.width - Theme.spacingXl - Theme.spacingSm
                    spacing: Theme.spacingSm

                    PasswordField {
                        id: psk
                        Layout.fillWidth: true
                        visible: row.askPsk
                        implicitHeight: 36
                        placeholder: "password for " + row.net.name
                        showCaps: true
                        failed: row.error !== ""
                        onAccepted: t => {
                            row.error = "";
                            row.net.connectWithPsk(t);
                        }
                        onEscaped: {
                            row.askPsk = false;
                            page.openName = "";
                        }
                        onVisibleChanged: if (visible) takeFocus()
                    }

                    RowLayout {
                        visible: row.net.connected || row.net.known
                        spacing: Theme.spacingXs

                        Text {
                            Layout.fillWidth: true
                            visible: row.net.connected
                            text: page.dev?.address ?? ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            color: Theme.textHint
                        }
                        Button {
                            visible: row.net.connected
                            compact: true
                            text: "disconnect"
                            onClicked: row.net.disconnect()
                        }
                        Button {
                            visible: row.net.known
                            compact: true
                            kind: "danger"
                            text: "forget"
                            onClicked: {
                                row.net.forget();
                                page.openName = "";
                            }
                        }
                    }
                }
            }
        }
    }

    Item { width: 1; height: Theme.spacingSm }

    // VPNs, 802.1X and everything else the picker doesn't do
    MenuRow {
        glyph: Icons.settings
        glyphColor: Theme.textMuted
        label: "Advanced settings…"
        onTriggered: Quickshell.execDetached(["nm-connection-editor"])
    }
}
