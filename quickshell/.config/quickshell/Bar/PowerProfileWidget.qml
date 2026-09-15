// Power profile via quickshell's native power-profiles-daemon D-Bus binding —
// event-driven. Click (or scroll) cycles saver → balanced → performance; one
// glyph per state so the current one is readable at a glance.
import QtQuick
import Quickshell.Services.UPower
import qs.Components
import qs.Theme

BarItem {
    id: root

    readonly property var order: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
    readonly property int profile: PowerProfiles.profile

    function name(p) {
        return p === PowerProfile.Performance ? "performance"
             : p === PowerProfile.PowerSaver ? "power saver"
             : "balanced";
    }

    function cycle(step) {
        let i = order.indexOf(profile);
        i = (i + step + order.length) % order.length;
        // performance may be missing on some machines
        if (order[i] === PowerProfile.Performance && !PowerProfiles.hasPerformanceProfile)
            i = (i + step + order.length) % order.length;
        PowerProfiles.profile = order[i];
    }

    tip: "power profile: " + name(profile)
    hint: "click / scroll: next profile"

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.profile === PowerProfile.Performance ? Icons.profilePerformance
             : root.profile === PowerProfile.PowerSaver ? Icons.profileSaver
             : Icons.profileBalanced
        color: root.profile === PowerProfile.Performance ? Theme.warning
             : root.profile === PowerProfile.PowerSaver ? Theme.success
             : Theme.textSecondary
    }

    onClicked: button => {
        if (button === Qt.LeftButton)
            cycle(1);
        else if (button === Qt.RightButton)
            cycle(-1);
    }
    onScrolled: delta => cycle(delta > 0 ? 1 : -1)
}
