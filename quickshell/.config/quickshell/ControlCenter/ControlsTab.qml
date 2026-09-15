pragma ComponentBehavior: Bound
// Controls tab: who/where header, volume / mic / brightness sliders, the
// quick-toggle grid and the media card.
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.Components
import qs.Services
import qs.Theme

Page {
    id: tab

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [tab.sink, tab.source].filter(Boolean)
    }

    // ── network / bluetooth summaries for the tiles ──
    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNet: wifiDev?.networks.values.find(n => n.connected) ?? null
    readonly property var wiredDev: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)

    function profileName(p) {
        return p === PowerProfile.Performance ? "performance"
             : p === PowerProfile.PowerSaver ? "power saver"
             : "balanced";
    }

    function cycleProfile() {
        const order = [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance];
        let i = (order.indexOf(PowerProfiles.profile) + 1) % order.length;
        if (order[i] === PowerProfile.Performance && !PowerProfiles.hasPerformanceProfile)
            i = (i + 1) % order.length;
        PowerProfiles.profile = order[i];
    }

    HeaderRow {
        width: parent.width
    }

    // ── sliders ──
    Rectangle {
        width: parent.width
        radius: Theme.radiusMedium
        color: Theme.surfaceRaised
        implicitHeight: sliders.implicitHeight + 2 * Theme.spacingSm

        Column {
            id: sliders
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Theme.spacingSm
            }
            spacing: 0

            SliderRow {
                width: parent.width
                glyph: Icons.volume(value, muted)
                color: Theme.teal
                value: tab.sink?.audio?.volume ?? 0
                muted: tab.sink?.audio?.muted ?? false
                rowEnabled: tab.sink !== null
                chevron: true
                onMoved: v => { if (tab.sink?.audio) tab.sink.audio.volume = v; }
                onIconClicked: if (tab.sink?.audio) tab.sink.audio.muted = !tab.sink.audio.muted
                onChevronClicked: Bus.controlCenter?.push("audio")
            }

            SliderRow {
                width: parent.width
                visible: tab.source !== null
                glyph: Icons.mic(muted)
                color: Theme.teal
                value: tab.source?.audio?.volume ?? 0
                muted: tab.source?.audio?.muted ?? false
                onMoved: v => { if (tab.source?.audio) tab.source.audio.volume = v; }
                onIconClicked: if (tab.source?.audio) tab.source.audio.muted = !tab.source.audio.muted
            }

            SliderRow {
                width: parent.width
                visible: Backlight.available
                glyph: Icons.brightness
                color: Theme.yellow
                value: Backlight.level
                onMoved: v => Backlight.set(v)
            }
        }
    }

    // ── quick toggles ──
    GridLayout {
        width: parent.width
        columns: 2
        columnSpacing: Theme.spacingSm
        rowSpacing: Theme.spacingSm

        QuickToggle {
            Layout.fillWidth: true
            glyph: tab.wifiNet ? Icons.wifi(Math.round((tab.wifiNet.signalStrength <= 1 ? tab.wifiNet.signalStrength * 100 : tab.wifiNet.signalStrength)))
                 : Networking.wifiEnabled ? Icons.wifiOff : Icons.wifiDisabled
            label: "Wi‑Fi"
            subtitle: !Networking.wifiHardwareEnabled ? "hardware switch off"
                    : !Networking.wifiEnabled ? "off"
                    : tab.wifiNet ? tab.wifiNet.name
                    : "not connected"
            active: Networking.wifiEnabled
            toggleEnabled: Networking.wifiHardwareEnabled
            hasPage: true
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            onOpened: Bus.controlCenter?.push("wifi")
        }

        QuickToggle {
            Layout.fillWidth: true
            visible: tab.adapter !== null
            glyph: tab.btConnected.length > 0 ? Icons.bluetoothConnected
                 : (tab.adapter?.enabled ?? false) ? Icons.bluetooth : Icons.bluetoothOff
            label: "Bluetooth"
            subtitle: tab.adapter?.state === BluetoothAdapterState.Enabling ? "turning on…"
                    : !(tab.adapter?.enabled ?? false) ? "off"
                    : tab.btConnected.length > 0 ? tab.btConnected.map(d => d.name).join(", ")
                    : "on"
            active: tab.adapter?.enabled ?? false
            hasPage: true
            onToggled: if (tab.adapter) tab.adapter.enabled = !tab.adapter.enabled
            onOpened: Bus.controlCenter?.push("bluetooth")
        }

        QuickToggle {
            Layout.fillWidth: true
            glyph: Notifs.dnd ? Icons.bellOff : Icons.bell
            label: "Do not disturb"
            subtitle: Notifs.dndLabel
            active: Notifs.dnd
            hasPage: true
            onToggled: Notifs.dnd = !Notifs.dnd
            onOpened: Bus.controlCenter?.push("dnd")
        }

        QuickToggle {
            Layout.fillWidth: true
            glyph: Caffeine.active ? Icons.caffeineOn : Icons.caffeineOff
            label: "Caffeine"
            subtitle: Caffeine.active ? "idle lock paused" : "off"
            active: Caffeine.active
            onToggled: Caffeine.toggle()
        }

        QuickToggle {
            Layout.fillWidth: true
            glyph: Icons.nightLight(NightLight.on)
            label: "Night light"
            subtitle: NightLight.on ? Config.nightLightKelvin + " K" : "off"
            active: NightLight.on
            onToggled: NightLight.toggle()
        }

        QuickToggle {
            Layout.fillWidth: true
            glyph: PowerProfiles.profile === PowerProfile.Performance ? Icons.profilePerformance
                 : PowerProfiles.profile === PowerProfile.PowerSaver ? Icons.profileSaver
                 : Icons.profileBalanced
            label: "Power profile"
            subtitle: tab.profileName(PowerProfiles.profile)
            active: true
            hasPage: true
            onToggled: tab.cycleProfile()
            onOpened: Bus.controlCenter?.push("power")
        }
    }

    MediaCard {
        width: parent.width
    }
}
