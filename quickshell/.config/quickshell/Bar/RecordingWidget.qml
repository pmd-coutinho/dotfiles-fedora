// Recording indicator — a red dot while screen-record is running, click to stop.
//
// State is pushed by the script (`qs ipc call recorder started|stopped`) rather
// than polled: the script owns the encoder process, so it is the only thing that
// actually knows. Clicking re-runs the script, which takes its own toggle path
// and stops the recording.
import QtQuick
import qs.Services
import qs.Theme

BarText {
    visible: Recorder.active
    text: "󰑊  rec"
    color: Theme.red
    font.weight: Font.Bold
    tip: "recording — click to stop"

    // pulse so it's noticeable in peripheral vision; you do not want to leave a
    // screen recording running by accident
    SequentialAnimation on opacity {
        running: Recorder.active
        loops: Animation.Infinite
        NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutQuad }
        NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
    }

    onModuleClicked: button => {
        if (button === Qt.LeftButton)
            Recorder.stop();
    }
}
