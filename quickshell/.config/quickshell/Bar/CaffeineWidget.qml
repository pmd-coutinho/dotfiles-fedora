// Caffeine toggle — while lit, the shell won't lock or blank the screens.
import QtQuick
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    active: Caffeine.active
    tip: Caffeine.active
        ? "caffeine on — idle lock and screen blanking suspended (suspend still locks)"
        : "caffeine off — lock at " + Math.round(Config.idle.ac.lock / 60) + "m, screens off at "
          + Math.round(Config.idle.ac.screensOff / 60) + "m"
    hint: "click: toggle"

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: Caffeine.active ? Icons.caffeineOn : Icons.caffeineOff
        color: Caffeine.active ? Theme.accent : Theme.textMuted
    }

    onClicked: button => {
        if (button === Qt.LeftButton)
            Caffeine.toggle();
    }
}
