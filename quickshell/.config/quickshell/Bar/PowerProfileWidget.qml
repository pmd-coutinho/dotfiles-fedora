// Power profile via quickshell's native power-profiles-daemon D-Bus binding —
// event-driven, replaces the old 5s busctl polling exec. (Still not
// powerprofilesctl: that spawned a whole python interpreter per call.)
import QtQuick
import Quickshell.Services.UPower
import qs.Theme

BarText {
    id: root

    text: PowerProfiles.profile === PowerProfile.Performance ? "󱐋"
        : PowerProfiles.profile === PowerProfile.PowerSaver ? "󰌪"
        : "󰾅"
    color: Theme.yellow
    tip: "power profile (L: performance · M: balanced · R: saver)"

    onModuleClicked: button => {
        if (button === Qt.LeftButton)
            PowerProfiles.profile = PowerProfile.Performance;
        else if (button === Qt.MiddleButton)
            PowerProfiles.profile = PowerProfile.Balanced;
        else if (button === Qt.RightButton)
            PowerProfiles.profile = PowerProfile.PowerSaver;
    }
}
