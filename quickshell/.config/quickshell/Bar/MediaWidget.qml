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

    visible: player !== null
    // cap the width: some titles are absurd, and the bar's centre island must
    // not get shoved around by whatever Vivaldi is playing
    width: Math.min(implicitWidth, 260)
    elide: Text.ElideRight
    color: Theme.pink

    text: {
        if (!player)
            return "";
        const glyph = player.isPlaying ? "󰎆" : "󰏤";
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
