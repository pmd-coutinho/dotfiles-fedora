pragma Singleton
// The "current" MPRIS player, shared by the bar widget and the panel card.
//
// The panel used to take Mpris.players.values[0] — an arbitrary pick that could
// land on a paused Firefox tab while Spotify was playing. Default to whatever is
// actually playing, and let the user cycle explicitly when several are up.
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values

    // dbusName of an explicitly chosen player, "" = follow whatever plays
    property string pinned: ""

    readonly property var player: {
        if (players.length === 0)
            return null;
        if (pinned !== "") {
            const p = players.find(p => p.dbusName === pinned);
            if (p)
                return p;
        }
        return players.find(p => p.isPlaying) ?? players[0];
    }

    readonly property bool active: player !== null

    function cycle() {
        if (players.length === 0)
            return;
        const cur = player;
        const i = players.indexOf(cur);
        pinned = players[(i + 1) % players.length].dbusName;
    }

    // a player disappearing should not leave us pinned to a corpse
    onPlayersChanged: {
        if (pinned !== "" && !players.some(p => p.dbusName === pinned))
            pinned = "";
    }
}
