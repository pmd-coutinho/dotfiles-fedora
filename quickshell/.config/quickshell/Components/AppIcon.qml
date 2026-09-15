// Themed application icon from a niri app_id. niri reports the desktop-entry
// id ("org.mozilla.firefox", "slack"), so DesktopEntries.byId hits directly for
// most apps; heuristicLookup covers the rest ("vivaldi-stable", odd casing).
// Falls back to the generic executable icon rather than an empty box.
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Theme

IconImage {
    property string appId
    property int size: Theme.iconSize

    implicitWidth: size
    implicitHeight: size
    source: {
        if (appId === "")
            return "";
        const e = DesktopEntries.byId(appId) ?? DesktopEntries.heuristicLookup(appId);
        return Quickshell.iconPath(e?.icon ?? appId, "application-x-executable");
    }
}
