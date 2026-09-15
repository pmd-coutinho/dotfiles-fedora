pragma ComponentBehavior: Bound
// Do-not-disturb duration. Critical notifications always show.
import QtQuick
import qs.Components
import qs.Services
import qs.Theme

Page {
    id: page

    title: "Do not disturb"

    // which preset was picked, so its radio stays lit while the deadline runs
    property int picked: -1

    Text {
        width: parent.width
        leftPadding: Theme.spacingSm
        text: Notifs.dnd ? "Do not disturb is " + Notifs.dndLabel : "Do not disturb is off"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontLabel
        color: Theme.textSecondary
    }

    MenuRow {
        checkable: true
        radio: true
        checked: !Notifs.dnd
        selected: checked
        label: "Off"
        onTriggered: {
            page.picked = -1;
            Notifs.dnd = false;
        }
    }

    Repeater {
        model: Config.dndPresets

        MenuRow {
            required property int modelData
            checkable: true
            radio: true
            checked: Notifs.dnd && Notifs.dndUntil > 0 && page.picked === modelData
            selected: checked
            label: modelData >= 60 ? (modelData / 60) + " hour" + (modelData >= 120 ? "s" : "") : modelData + " minutes"
            onTriggered: {
                page.picked = modelData;
                Notifs.setDndFor(modelData);
            }
        }
    }

    MenuRow {
        checkable: true
        radio: true
        checked: Notifs.dnd && Notifs.dndUntil > 0 && page.picked === 0
        selected: checked
        label: "Until tomorrow 08:00"
        onTriggered: {
            page.picked = 0;
            Notifs.setDndUntilTomorrow();
        }
    }

    MenuRow {
        checkable: true
        radio: true
        checked: Notifs.dnd && Notifs.dndUntil === 0
        selected: checked
        label: "Until I turn it off"
        onTriggered: {
            page.picked = -1;
            Notifs.dndUntil = 0;
            Notifs.dnd = true;
        }
    }

    Text {
        width: parent.width
        topPadding: Theme.spacingSm
        leftPadding: Theme.spacingSm
        wrapMode: Text.Wrap
        text: "Critical notifications still pop up. Everything else lands in the list silently."
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        color: Theme.textHint
    }
}
