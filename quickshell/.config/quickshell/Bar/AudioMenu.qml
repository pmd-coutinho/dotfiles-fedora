// Audio device picker (middle-click on the volume module). The lists live in
// AudioDevices.qml, shared with the control center's audio page; window
// placement, the dismiss scrim and the menu box come from MenuWindow.qml.
import QtQuick
import qs.Services

MenuWindow {
    id: menuWin

    // card profiles come from pactl, so only pay for them when opening
    onAboutToOpen: AudioCards.refresh()

    // used by the bar's volume tooltip
    function label(node) {
        return devices.label(node);
    }

    AudioDevices {
        id: devices
        onPicked: menuWin.close()
    }
}
