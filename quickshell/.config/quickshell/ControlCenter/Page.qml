// Base for every StackView page: a title for the drawer's top bar and a
// scrolling column of content.
import QtQuick
import qs.Theme

Item {
    id: page

    property string title: ""
    default property alias content: col.data
    readonly property alias flickable: flick

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: Theme.spacingSm
        }
    }
}
