// One bar widget: hover / pressed / active washes, tooltip plumbing, click and
// scroll signals, and animated show/hide. Put an Icon plus an optional Text or
// Ring inside; it lays them out in a Row.
//
// Show/hide animates `implicitWidth` to 0 rather than flipping `visible`: the
// island's RowLayout reads implicitWidth, so the neighbours slide instead of
// jumping. (Behaviors don't fire on the initial binding, so an item created
// hidden starts at 0 without animating in.) Property is deliberately called
// `shown`, not `visible` — a property named `visible`/`enabled`/`width` here
// would shadow Item's and break in ways the shell has already been bitten by.
import QtQuick
import QtQuick.Layouts
import qs.Theme

Item {
    id: root

    property var bar                      // the PanelWindow (tooltip host, screen)
    property string tip: ""               // tooltip title
    property string hint: ""              // tooltip second line (keys / legend)
    property bool interactive: true
    property bool active: false           // "lit": caffeine on, menu open, panel open
    property bool shown: true
    property int padX: Theme.barItemPadX
    property int gap: Theme.spacingXs
    // extra fill under the state washes (battery-critical pulse)
    property color wash: "transparent"
    readonly property alias hovered: mouse.containsMouse
    readonly property alias pressed: mouse.pressed
    default property alias content: row.data

    signal clicked(int button)
    signal scrolled(int delta)

    implicitHeight: Theme.barItemHeight
    implicitWidth: shown ? row.implicitWidth + 2 * padX : 0
    // Rigid by default: an island that gets clamped must squeeze the elastic
    // items (title, media), not the icons. Elastic items set this to 0.
    Layout.minimumWidth: implicitWidth
    opacity: shown ? 1 : 0
    // stays laid out while the width animates to 0, then drops out of the layout
    visible: implicitWidth > 0.5
    clip: !shown

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easeStandard }
    }
    Behavior on opacity {
        NumberAnimation { duration: Theme.durationShort }
    }

    onShownChanged: if (!shown && bar) bar.hideTip(root)

    Rectangle {
        anchors.fill: parent
        radius: height / 2   // pill
        color: !root.interactive ? root.wash
             : mouse.pressed ? Theme.statePressed
             : root.active ? Theme.accentSubtle
             : mouse.containsMouse ? Theme.stateHover
             : root.wash

        Behavior on color {
            ColorAnimation { duration: Theme.durationFast }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        height: parent.height
        spacing: root.gap
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive || root.tip !== ""
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: root.interactive ? (Qt.LeftButton | Qt.MiddleButton | Qt.RightButton) : Qt.NoButton
        onClicked: m => root.clicked(m.button)
        onWheel: w => root.scrolled(w.angleDelta.y)
        onEntered: if (root.tip !== "") root.bar?.showTip(root)
        onExited: root.bar?.hideTip(root)
    }
}
