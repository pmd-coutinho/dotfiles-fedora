pragma Singleton
// ALSA card profiles, for the audio picker.
//
// Why this exists: a sink hidden behind an INACTIVE card profile does not appear
// in Pipewire.nodes at all, so the device picker couldn't offer it. That is not
// hypothetical — this laptop's SOF card puts Speaker and Headphones in mutually
// exclusive profiles, and sitting in the wrong one makes the speakers vanish
// entirely (see bin/audio-jack-profile).
//
// quickshell 0.3.0's Pipewire module exposes nodes and links but no cards, so
// this shells out to pactl. JSON in, JSON out — no text scraping.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // [{ name, description, active, profiles: [{ name, priority, sinks, sources }] }]
    // Only cards worth showing: see filter() below.
    property var cards: []

    readonly property int maxProfilesPerCard: 6

    function refresh() {
        query.running = true;
    }

    function setProfile(cardName, profileName) {
        Quickshell.execDetached(["pactl", "set-card-profile", cardName, profileName]);
        // pactl returns before the profile is applied and nodes re-appear
        settle.restart();
    }

    Timer {
        id: settle
        interval: 600
        onTriggered: root.refresh()
    }

    Process {
        id: query
        command: ["pactl", "-f", "json", "list", "cards"]

        stdout: StdioCollector {
            onStreamFinished: {
                let parsed;
                try {
                    parsed = JSON.parse(text);
                } catch (e) {
                    console.warn("AudioCards: could not parse pactl output:", e);
                    return;
                }
                root.cards = root.filter(parsed);
            }
        }
    }

    // Keep the menu useful rather than exhaustive:
    //   - drop "off" and "pro-audio" (priority <= 1, never what you want here)
    //   - drop profiles pactl marks unavailable (no cable, no hardware)
    //   - drop cards left with fewer than two choices — nothing to switch
    // On this machine that hides the NVIDIA HDMI card (14 profiles, only
    // off/pro-audio actually available) and surfaces the two that matter.
    function filter(raw) {
        const out = [];
        for (const card of raw) {
            const profiles = [];
            const all = card.profiles ?? {};
            for (const name in all) {
                const p = all[name] ?? {};
                if (name === "off" || name === "pro-audio")
                    continue;
                if (p.available === false)
                    continue;
                profiles.push({
                    name: name,
                    priority: p.priority ?? 0,
                    sinks: p.sinks ?? 0,
                    sources: p.sources ?? 0
                });
            }
            if (profiles.length < 2)
                continue;
            profiles.sort((a, b) => b.priority - a.priority);
            // A USB mic can offer eight analog/iec958 permutations; the top few
            // by priority are the ones anyone actually picks, and an unbounded
            // list would push the device rows off screen.
            profiles.splice(maxProfilesPerCard);
            out.push({
                name: card.name,
                description: card.properties?.["device.description"] ?? card.name,
                active: card.active_profile ?? "",
                profiles: profiles
            });
        }
        return out;
    }
}
