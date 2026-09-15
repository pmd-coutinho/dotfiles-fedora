// Night light toggle — state comes from the NightLight service that owns
// wlsunset (no pgrep polling, no pkill -RTMIN+8 refresh hack).
import QtQuick
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    active: NightLight.on
    tip: "night light " + (NightLight.on ? "on · " + Config.nightLightKelvin + " K" : "off")
    hint: "click: toggle"

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: Icons.nightLight(NightLight.on)
        color: NightLight.on ? Theme.warning : Theme.textMuted
    }

    onClicked: button => {
        if (button === Qt.LeftButton)
            NightLight.toggle();
    }
}
