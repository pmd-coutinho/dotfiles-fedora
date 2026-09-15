pragma ComponentBehavior: Bound
// Output / input device lists plus card profiles — the body of the control
// center's audio page (right-click on the volume module). Fully native: Pipewire.preferredDefaultAudioSink is writable, so picking
// is a property assignment, not a `wpctl set-default` shell-out.
import QtQuick
import Quickshell.Services.Pipewire
import qs.Components
import qs.Services
import qs.Theme

Column {
    id: root

    signal picked()

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

    function label(node) {
        return node.description !== "" ? node.description
            : node.nickname !== "" ? node.nickname
            : node.name;
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

    // without this the listed nodes report empty descriptions and null audio —
    // pipewire object metadata is only bound while something tracks it
    PwObjectTracker {
        objects: root.sinks.concat(root.sources)
    }

    width: parent ? parent.width : implicitWidth

    SectionHeader { text: "output" }

    Repeater {
        model: root.sinks

        MenuRow {
            required property var modelData
            checkable: true
            radio: true
            checked: Pipewire.defaultAudioSink === modelData
            selected: checked
            label: root.label(modelData)
            detail: modelData.audio ? Math.round(modelData.audio.volume * 100) + "%" : ""
            onTriggered: {
                // the *preferred* default: pipewire remembers it, and it survives
                // the device disappearing and coming back (bluetooth reconnects)
                Pipewire.preferredDefaultAudioSink = modelData;
                root.picked();
            }
        }
    }

    SectionHeader { text: "input" }

    Repeater {
        model: root.sources

        MenuRow {
            required property var modelData
            checkable: true
            radio: true
            checked: Pipewire.defaultAudioSource === modelData
            selected: checked
            label: root.label(modelData)
            detail: modelData.audio ? Math.round(modelData.audio.volume * 100) + "%" : ""
            onTriggered: {
                Pipewire.preferredDefaultAudioSource = modelData;
                root.picked();
            }
        }
    }

    // ── card profiles ──
    // The lists above can only show sinks that EXIST, and a sink behind an
    // inactive card profile doesn't. This is the escape hatch for "my speakers
    // aren't in the list at all".
    Repeater {
        model: AudioCards.cards

        Column {
            id: cardEntry

            required property var modelData

            width: parent.width

            SectionHeader { text: "profile · " + cardEntry.modelData.description }

            Repeater {
                model: cardEntry.modelData.profiles

                MenuRow {
                    required property var modelData
                    // reached by id, not a parent.parent chain: the delegate's
                    // parent is the Column, not this Repeater
                    readonly property var card: cardEntry.modelData
                    checkable: true
                    radio: true
                    checked: card.active === modelData.name
                    selected: checked
                    label: root.profileLabel(modelData.name)
                    onTriggered: {
                        AudioCards.setProfile(card.name, modelData.name);
                        root.picked();
                    }
                }
            }
        }
    }
}
