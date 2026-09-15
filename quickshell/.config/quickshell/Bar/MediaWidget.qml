// Now-playing in the bar: play/pause glyph + elided title. Hidden entirely when
// nothing is playing, so the bar doesn't carry dead weight.
//
// The player comes from Services/Media.qml, shared with the control center's
// media card, so both always control the same thing.
//
// This is one of the two ELASTIC bar items: its implicitWidth is computed from
// the children's implicit sizes (not the Row's actual widths) and the title's
// width follows the item's — so the island can squeeze it without a binding
// loop, and it is the first thing to give way when the clock needs room.
import QtQuick
import QtQuick.Layouts
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    id: root

    readonly property var player: Media.player
    readonly property string title: {
        if (!player)
            return "";
        const t = player.trackTitle ?? "";
        const a = player.trackArtist ?? "";
        if (t === "")
            return player.identity ?? "";
        return a !== "" ? a + " — " + t : t;
    }

    shown: player !== null
    Layout.minimumWidth: 0
    Layout.maximumWidth: Theme.mediaMaxWidth
    // An elided Text whose width follows ours reports implicitWidth 0, so the
    // natural width has to come from a separate measurement.
    implicitWidth: shown
        ? Math.min(Theme.mediaMaxWidth, glyph.implicitWidth + gap + Math.ceil(metrics.advanceWidth) + 2 * padX)
        : 0
    // below this there's no room for a useful amount of text — fade rather
    // than render a two-character stub (opacity doesn't feed back into layout)
    opacity: shown && width >= 70 ? 1 : 0

    TextMetrics {
        id: metrics
        font: label.font
        text: root.title
    }

    tip: {
        if (!player)
            return "";
        const lines = [player.trackTitle ?? "", player.trackArtist ?? "", player.trackAlbum ?? ""]
            .filter(s => s !== "");
        lines.push(player.identity ?? player.dbusName);
        return lines.join("\n");
    }
    hint: "click: play/pause · right: next · middle: switch player"
        + (Media.players.length > 1 ? " (" + Media.players.length + " open)" : "")

    Icon {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        // the glyph is the ACTION, matching the transport buttons: playing shows
        // pause, paused shows play
        glyph: root.player?.isPlaying ? Icons.pause : Icons.play
        color: Theme.pink
    }

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.width - 2 * root.padX - glyph.width - root.gap)
        text: root.title
        elide: Text.ElideRight
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontLabel
        font.weight: Theme.weightMedium
        color: Theme.textSecondary
    }

    onClicked: button => {
        if (!player)
            return;
        if (button === Qt.LeftButton && player.canTogglePlaying)
            player.togglePlaying();
        else if (button === Qt.RightButton && player.canGoNext)
            player.next();
        else if (button === Qt.MiddleButton)
            Media.cycle();
    }
}
