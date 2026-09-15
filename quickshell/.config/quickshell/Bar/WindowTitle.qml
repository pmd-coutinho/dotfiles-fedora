// Focused window of this output's active workspace: app icon + title, elided
// by width (not sliced at a character count). The second ELASTIC bar item —
// see MediaWidget.qml for why implicitWidth is computed from measured sizes.
import QtQuick
import QtQuick.Layouts
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    id: root

    property string output

    readonly property var win: Niri.activeWindowOn(output)
    readonly property string title: win?.title ?? ""

    interactive: false
    shown: title !== ""
    tip: title
    // see MediaWidget.qml: elastic = fillWidth capped at the natural width
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    Layout.maximumWidth: implicitWidth
    // An elided Text whose width follows ours reports implicitWidth 0, so the
    // natural width has to come from a separate measurement.
    implicitWidth: shown
        ? Math.min(Theme.titleMaxWidth, icon.implicitWidth + gap + Math.ceil(metrics.advanceWidth) + 2 * padX)
        : 0

    TextMetrics {
        id: metrics
        font: label.font
        text: root.title
    }

    AppIcon {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        appId: root.win?.app_id ?? ""
    }

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.width - 2 * root.padX - icon.width - root.gap)
        text: root.title
        elide: Text.ElideRight
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontLabel
        font.weight: Theme.weightMedium
        color: Theme.textSecondary
    }
}
