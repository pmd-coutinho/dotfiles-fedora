// Caffeine toggle — while lit, the shell won't lock or blank the screens.
import QtQuick
import qs.Services
import qs.Theme

BarText {
    text: Caffeine.active ? Icons.caffeineOn : Icons.caffeineOff
    color: Caffeine.active ? Theme.yellow : Theme.overlay0
    tip: Caffeine.active
        ? "caffeine ON — idle lock and screen blanking suspended\n(suspend still locks)"
        : "caffeine off — lock at 10m, screens off at 15m"

    onModuleClicked: button => {
        if (button === Qt.LeftButton)
            Caffeine.toggle();
    }
}
