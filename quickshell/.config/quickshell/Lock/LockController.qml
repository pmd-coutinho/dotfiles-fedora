// The lock's state machine, shared by the real locker (Lock.qml) and the
// preview harness (LockPreview.qml): PAM, failure backoff, and the fade in /
// fade out.
//
// Session.locked stays the single source of truth and the only thing PAM
// writes. `held` is what ext-session-lock actually sees: it goes true the
// instant Session.locked does — the security path has no animation in front
// of it — and goes false only after the unlock fade, with a guard timer so it
// can never stay held if the animation never runs (e.g. every output is off).
import QtQuick
import Quickshell
import Quickshell.Services.Pam
import qs.Services
import qs.Theme

Scope {
    id: ctl

    readonly property bool locked: Session.locked
    property bool held: false
    // 0 = crust, 1 = full content; drives every surface's opacity
    property real reveal: 0

    property string password: ""
    property int attempts: 0
    property bool failed: false
    property bool checking: false
    property bool throttled: false
    property int backoffLeft: 0

    // Failed attempts add a growing delay before the next try, so a mashed
    // keyboard can't spin PAM. Capped so a genuine typo isn't a minute-long
    // lockout: 0s, 1s, 2s, 4s, 8s, 8s…
    readonly property int backoffMs: attempts === 0 ? 0 : Math.min(8000, 500 * Math.pow(2, attempts))

    readonly property string status: checking ? ""
                                   : throttled ? "wait " + backoffLeft + " s"
                                   : failed ? "wrong password" + (attempts > 1 ? " (" + attempts + ")" : "")
                                   : ""

    // a password was refused: the field shakes
    signal rejected()

    function tryUnlock(pw) {
        if (checking || throttled || pw === "")
            return;
        password = pw;
        checking = true;
        pam.start();
    }

    onLockedChanged: {
        if (locked) {
            attempts = 0;
            failed = false;
            throttled = false;
            password = "";
            exitAnim.stop();
            releaseGuard.stop();
            held = true;                   // lock IMMEDIATELY, no animation gate
            enterAnim.restart();
        } else {
            enterAnim.stop();
            exitAnim.restart();            // fade to crust, then release
            releaseGuard.restart();
        }
    }

    NumberAnimation {
        id: enterAnim
        target: ctl
        property: "reveal"
        to: 1
        duration: Theme.durationLong
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: exitAnim
        NumberAnimation { target: ctl; property: "reveal"; to: 0; duration: Theme.durationMedium; easing.type: Easing.InCubic }
        ScriptAction { script: ctl.held = false }
    }

    Timer {
        id: releaseGuard
        interval: Theme.durationMedium + 250
        onTriggered: if (!ctl.locked) ctl.held = false
    }

    Timer {
        id: backoff
        interval: ctl.backoffMs
        onTriggered: ctl.throttled = false
    }

    // the countdown the status line shows while throttled
    Timer {
        interval: 1000
        repeat: true
        running: ctl.throttled
        onTriggered: ctl.backoffLeft = Math.max(0, ctl.backoffLeft - 1)
    }

    PamContext {
        id: pam

        onPamMessage: {
            if (responseRequired)
                respond(ctl.password);
        }
        onCompleted: result => {
            ctl.checking = false;
            ctl.password = "";
            if (result === PamResult.Success) {
                ctl.attempts = 0;
                ctl.failed = false;
                Session.locked = false;
            } else {
                ctl.attempts += 1;
                ctl.failed = true;
                ctl.throttled = true;
                ctl.backoffLeft = Math.ceil(ctl.backoffMs / 1000);
                backoff.restart();
                ctl.rejected();
            }
        }
    }
}
