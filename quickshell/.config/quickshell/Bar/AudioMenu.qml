pragma ComponentBehavior: Bound
// Audio device picker — switch the default output (or input) without opening
// pavucontrol. Fully native: Pipewire.preferredDefaultAudioSink is writable, so
// this is a property assignment, not a `wpctl set-default` shell-out.
//
// Same shape as TrayMenu.qml and for the same reasons: ONE global window that
// moves to the clicked widget's screen on open (a per-bar window nested in the
// Variants delegate ends up mapped on the wrong output), with a transparent
// scrim below the bar to catch outside clicks.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.Services
import qs.Theme

PanelWindow {
    id: menuWin

    property var anchorSlot: null
    property real menuX: 0

    readonly property int boxWidth: 320

    // Real devices only: `isStream` excludes per-application playback/record
    // streams, and requiring `audio` drops the webcam (a non-audio Source).
    //
    // Sorted by label because pipewire hands them over in node-creation order,
    // which reshuffles whenever a device comes or goes (bluetooth reconnect,
    // USB mic replug) — the rows have to stay put to be clickable from memory.
    readonly property var sinks: Pipewire.nodes.values
        .filter(n => n.audio && n.isSink && !n.isStream)
        .sort((a, b) => label(a).localeCompare(label(b)))
    readonly property var sources: Pipewire.nodes.values
        .filter(n => n.audio && !n.isSink && !n.isStream)
        .sort((a, b) => label(a).localeCompare(label(b)))

    function openFor(item, scr) {
        // clicking the same widget again closes the menu
        if (visible && anchorSlot === item) {
            close();
            return;
        }
        // card profiles come from pactl, so only pay for them when opening
        AudioCards.refresh();
        screen = scr;
        const centerX = Theme.barMarginSide + item.mapToItem(null, item.width / 2, 0).x;
        menuX = Math.min(Math.max(8, centerX - boxWidth / 2), scr.width - boxWidth - 8);
        anchorSlot = item;
        visible = true;
    }

    function close() {
        visible = false;
        anchorSlot = null;
    }

    function label(node) {
        return node.description !== "" ? node.description
            : node.nickname !== "" ? node.nickname
            : node.name;
    }

    visible: false
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    // scrim starts below the bar, so the bar stays interactive while open
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"

    // without this the listed nodes report empty descriptions and null audio —
    // pipewire object metadata is only bound while something tracks it
    PwObjectTracker {
        objects: menuWin.sinks.concat(menuWin.sources)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: menuWin.close()
    }

    component DeviceRow: Rectangle {
        id: row

        required property var node
        required property bool isDefault
        // set the *preferred* default: pipewire remembers it, and it survives
        // the device disappearing and coming back (bluetooth reconnects)
        required property var onPick

        width: parent.width
        height: 28
        radius: Theme.radiusSmall
        color: rowArea.containsMouse ? Theme.surface0 : "transparent"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 8
            width: 16
            text: row.isDefault ? Icons.checked : Icons.unchecked
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            color: row.isDefault ? Theme.mauve : Theme.overlay0
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 30
            width: parent.width - 76
            elide: Text.ElideRight
            text: menuWin.label(row.node)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            font.weight: row.isDefault ? Font.Bold : Font.Normal
            color: row.isDefault ? Theme.text : Theme.subtext0
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: row.node.audio ? Math.round(row.node.audio.volume * 100) + "%" : ""
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            color: Theme.overlay1
        }

        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                row.onPick(row.node);
                menuWin.close();
            }
        }
    }

    component SectionHeader: Text {
        leftPadding: 8
        topPadding: 4
        bottomPadding: 2
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.weight: Font.Bold
        color: Theme.mauve
    }

    Rectangle {
        x: menuWin.menuX
        y: 4
        width: menuWin.boxWidth
        height: list.implicitHeight + 12
        radius: Theme.islandRadius
        color: Theme.alpha(Theme.mantle, 0.98)
        border.width: 1
        border.color: Theme.surface0

        Column {
            id: list
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 6

            SectionHeader { text: "output" }

            Repeater {
                model: menuWin.sinks

                DeviceRow {
                    required property var modelData
                    node: modelData
                    isDefault: Pipewire.defaultAudioSink === modelData
                    onPick: n => Pipewire.preferredDefaultAudioSink = n
                }
            }

            SectionHeader { text: "input" }

            Repeater {
                model: menuWin.sources

                DeviceRow {
                    required property var modelData
                    node: modelData
                    isDefault: Pipewire.defaultAudioSource === modelData
                    onPick: n => Pipewire.preferredDefaultAudioSource = n
                }
            }

            // ── card profiles ──
            // The lists above can only show sinks that EXIST, and a sink behind
            // an inactive card profile doesn't. This is the escape hatch for
            // "my speakers aren't in the list at all".
            Repeater {
                model: AudioCards.cards

                Column {
                    id: cardEntry

                    required property var modelData

                    width: parent.width

                    SectionHeader {
                        width: parent.width
                        elide: Text.ElideRight
                        text: "profile · " + cardEntry.modelData.description
                    }

                    Repeater {
                        model: cardEntry.modelData.profiles

                        Rectangle {
                            id: prow

                            required property var modelData
                            // reached by id, not a parent.parent chain: the
                            // delegate's parent is the Column, not this Repeater
                            readonly property var card: cardEntry.modelData
                            readonly property bool isActive: card.active === modelData.name

                            width: cardEntry.width
                            height: 26
                            radius: Theme.radiusSmall
                            color: parea.containsMouse ? Theme.surface0 : "transparent"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 8
                                width: 16
                                text: prow.isActive ? Icons.checked : Icons.unchecked
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                color: prow.isActive ? Theme.mauve : Theme.overlay0
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 30
                                width: parent.width - 38
                                elide: Text.ElideRight
                                text: menuWin.profileLabel(prow.modelData.name)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.weight: prow.isActive ? Font.Bold : Font.Normal
                                color: prow.isActive ? Theme.text : Theme.subtext0
                            }

                            MouseArea {
                                id: parea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    AudioCards.setProfile(prow.card.name, prow.modelData.name);
                                    menuWin.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Profile names come in two dialects, both unreadable at a glance:
    //   UCM:   "HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)"
    //   pulse: "output:analog-stereo+input:iec958-stereo"
    // Keep only what distinguishes one profile from its siblings.
    function profileLabel(name) {
        const inner = name.match(/\(([^)]*)\)/)?.[1];
        if (inner) {
            // UCM: the HDMI/Mic entries are on every profile, so they carry no
            // information — what differs is Speaker vs Headphones
            const kept = inner.split(",")
                .map(s => s.trim())
                .filter(s => !/^(HDMI\d*|Mic\d*)$/i.test(s));
            return kept.length > 0 ? kept.join(" + ") : name;
        }
        if (name.includes(":")) {
            return name.split("+")
                .map(part => part.replace(/^output:/, "out ").replace(/^input:/, "in "))
                .join(" + ");
        }
        return name;
    }
}
