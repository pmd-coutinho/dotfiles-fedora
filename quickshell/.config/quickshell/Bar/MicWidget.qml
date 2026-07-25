// Mic-in-use privacy indicator — only visible while something is actually
// recording, so an unexpected dot is worth investigating.
//
// Detection is by pipewire LINK, not audio level: PwNodeLinkTracker tells us an
// application is connected to the default source. A peak monitor would miss an
// app that is recording silence and would cost continuous sampling for a widget
// that is usually hidden.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Theme

BarText {
    id: root

    readonly property PwNode source: Pipewire.defaultAudioSource

    // linkGroups is a plain list property, not an ObjectModel — no `.values`,
    // and JS array methods aren't available on it, hence the explicit loop.
    readonly property var consumers: {
        const out = [];
        const groups = tracker.linkGroups;
        if (!groups || !root.source)
            return out;
        for (let i = 0; i < groups.length; i++) {
            const g = groups[i];
            if (g && (g.target === root.source || g.source === root.source))
                out.push(g);
        }
        return out;
    }

    readonly property bool inUse: consumers.length > 0
    readonly property bool muted: source?.audio?.muted ?? false

    PwNodeLinkTracker {
        id: tracker
        node: root.source
    }

    // metadata on the peer nodes has to be tracked for their names to resolve
    PwObjectTracker {
        objects: root.consumers
            .map(g => g.target === root.source ? g.source : g.target)
            .filter(Boolean)
    }

    visible: inUse
    // muted-but-recording is worth showing differently: the app is capturing,
    // it just gets silence
    text: muted ? Icons.micOff : Icons.micOn
    color: muted ? Theme.overlay0 : Theme.red
    font.weight: Font.Bold

    tip: {
        if (!inUse)
            return "";
        const names = root.consumers
            .map(g => {
                const peer = g.target === root.source ? g.source : g.target;
                return peer?.description ?? peer?.name ?? "?";
            })
            .filter(n => n !== "?");
        const head = muted ? "mic in use (muted)" : "mic in use";
        return names.length > 0 ? head + "\n\n" + names.join("\n") : head;
    }

    onModuleClicked: button => {
        if (button === Qt.LeftButton && source?.audio)
            source.audio.muted = !source.audio.muted;
        else if (button === Qt.RightButton)
            Quickshell.execDetached(["pavucontrol"]);
    }
}
