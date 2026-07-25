// Now-playing in the bar: play/pause glyph + elided title. Hidden entirely when
// nothing is playing, so the bar doesn't carry dead weight.
//
// The player comes from Services/Media.qml, shared with the notification
// panel's media card, so both always control the same thing.
import QtQuick
import qs.Services
import qs.Theme

BarText {
    id: root

    readonly property var player: Media.player

    // Space the bar can spare for us, set by Bar.qml from the gap between the
    // clock and the right edge. 260 is only the ceiling for a wide output — a
    // long title would otherwise run into the clock on a 1920-wide screen.
    property real maxWidth: 260

    // below this there's no room for a useful amount of text, so don't render a
    // two-character stub
    visible: player !== null && maxWidth >= 70
    width: Math.min(implicitWidth, maxWidth, 260)
    elide: Text.ElideRight
    color: Theme.pink

    text: {
        if (!player)
            return "";
        // the glyph is the ACTION, matching the panel's transport buttons:
        // playing shows pause, paused shows play
        const glyph = player.isPlaying ? Icons.pause : Icons.play;
        const title = player.trackTitle ?? "";
        const artist = player.trackArtist ?? "";
        if (title === "")
            return glyph + "  " + (player.identity ?? "");
        return glyph + "  " + (artist !== "" ? artist + " — " + title : title);
    }

    tip: {
        if (!player)
            return "";
        const lines = [player.trackTitle ?? "", player.trackArtist ?? "", player.trackAlbum ?? ""]
            .filter(s => s !== "");
        lines.push("");
        lines.push(player.identity ?? player.dbusName);
        lines.push("L: play/pause · R: next · M: switch player"
            + (Media.players.length > 1 ? " (" + Media.players.length + " open)" : ""));
        return lines.join("\n");
    }

    onModuleClicked: button => {
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
