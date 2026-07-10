// Night light toggle — state comes from the NightLight service that owns
// wlsunset (no pgrep polling, no pkill -RTMIN+8 refresh hack).
import QtQuick
import qs.Services
import qs.Theme

BarText {
    text: NightLight.on ? "󰖔" : "󰖨"
    color: NightLight.on ? Theme.peach : Theme.overlay0
    tip: "night light: " + (NightLight.on ? "on" : "off")

    onModuleClicked: button => {
        if (button === Qt.LeftButton)
            NightLight.toggle();
    }
}
