// One floating pill ("island"): shared Surface chrome with a RowLayout inside.
//
// Children are layout items, so they must not anchor vertically (the layout
// centres them) and they size through implicitWidth. Rigid items pin
// Layout.minimumWidth to their implicitWidth (BarItem does this by default);
// the two elastic ones (window title, media title) leave it at 0, so when
// Bar.qml clamps this island's width they are what shrinks.
import QtQuick
import QtQuick.Layouts
import qs.Components
import qs.Theme

Surface {
    id: island

    default property alias items: layout.data

    elevation: 1
    radius: height / 2   // pill
    height: Theme.barHeight
    implicitWidth: layout.implicitWidth + 2 * Theme.islandPadX

    // smooth clock toggles and title changes instead of a snap
    Behavior on width {
        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easeStandard }
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: Theme.islandPadX
        anchors.rightMargin: Theme.islandPadX
        spacing: Theme.barItemGap
    }
}
