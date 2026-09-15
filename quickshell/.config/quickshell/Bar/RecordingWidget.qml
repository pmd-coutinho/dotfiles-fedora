// Recording indicator — a breathing red dot while screen-record is running,
// click to stop.
//
// State is pushed by the script (`qs ipc call recorder started|stopped`) rather
// than polled: the script owns the encoder process, so it is the only thing that
// actually knows. Clicking re-runs the script, which takes its own toggle path
// and stops the recording.
import QtQuick
import qs.Components
import qs.Services
import qs.Theme

BarItem {
    shown: Recorder.active
    tip: "recording"
    hint: "click: stop"

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: Icons.recording
        color: Theme.error

        // pulse so it's noticeable in peripheral vision; you do not want to leave
        // a screen recording running by accident
        SequentialAnimation on opacity {
            running: Recorder.active
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: Theme.durationPulse; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: Theme.durationPulse; easing.type: Easing.InOutQuad }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "rec"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontLabel
        font.weight: Theme.weightBold
        color: Theme.error
    }

    onClicked: button => {
        if (button === Qt.LeftButton)
            Recorder.stop();
    }
}
