// Base text module: waybar-ish padding, hover tooltip, click/scroll signals.
import QtQuick
import qs.Theme

Text {
    id: root

    // the enclosing bar (provides showTip/hideTip); set by Bar.qml delegates
    property var bar
    property string tip: ""

    signal moduleClicked(int button)
    signal moduleScrolled(int delta)

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    leftPadding: 10
    rightPadding: 10
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Font.Medium
    color: Theme.subtext0
    verticalAlignment: Text.AlignVCenter

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
        onClicked: mouse => root.moduleClicked(mouse.button)
        onWheel: wheel => root.moduleScrolled(wheel.angleDelta.y)
        onEntered: if (root.tip !== "" && root.bar) root.bar.showTip(root)
        onExited: if (root.bar) root.bar.hideTip(root)
    }
}
