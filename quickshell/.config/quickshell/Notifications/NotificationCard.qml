pragma ComponentBehavior: Bound
// One notification card — a toast (isPopup) or a history entry. Renders from a
// Notifs RECORD, never a live Notification, so it stays legible while sliding
// out after the server has destroyed the object, and restored-from-disk
// entries look the same as live ones (minus action buttons).
//
// Toast gestures: left click activates (default action + focus the app),
// middle click or a swipe to the right dismisses without activating, hovering
// pauses the countdown drawn along the bottom edge.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.Components
import qs.Services
import qs.Theme

Surface {
    id: card

    required property var entry
    // toast group / history group this card fronts (count badge, group dismiss)
    property var group: null
    property bool isPopup: false
    // history sub-entry inside an expanded app group: no icon column
    property bool compact: false

    readonly property int count: group?.count ?? 1
    readonly property var live: entry?.notif ?? null
    readonly property int urgency: entry?.urgency ?? NotificationUrgency.Normal
    readonly property bool critical: urgency === NotificationUrgency.Critical
    readonly property bool low: urgency === NotificationUrgency.Low
    readonly property int timeout: Notifs.timeoutFor(entry)
    readonly property string appName: entry?.appName ?? ""
    readonly property string imageSrc: (entry?.image ?? "") !== "" ? entry.image
                                     : (entry?.appIcon ?? "") !== "" ? Quickshell.iconPath(entry.appIcon, true)
                                     : ""
    readonly property bool hasBoth: (entry?.image ?? "") !== "" && (entry?.appIcon ?? "") !== ""
    readonly property var actions: (live?.actions ?? []).filter(a => a.identifier !== "default")
    property bool actionsExpanded: false
    property real progress: 1

    signal dismissRequested()

    function hashColor(s) {
        let h = 0;
        for (let i = 0; i < s.length; i++)
            h = (h * 31 + s.charCodeAt(i)) & 0xffff;
        const pal = Wallpapers.accentPalette;
        return pal[h % pal.length];
    }

    function dismiss() {
        if (group && !compact)
            Notifs.dismissGroup(group);
        else
            Notifs.dismissEntry(entry);
    }

    elevation: isPopup ? 2 : 0
    radius: Theme.radiusLarge
    color: isPopup ? Theme.surface : Theme.surfaceRaised
    borderColor: critical ? Theme.alpha(Theme.error, 0.6) : Theme.outline
    implicitHeight: layout.implicitHeight + 2 * Theme.spacingMd
    opacity: 1 - Math.min(1, Math.max(0, x) / Math.max(1, width))

    // ── countdown (toasts) ──
    NumberAnimation {
        id: countdown
        target: card
        property: "progress"
        from: 1
        to: 0
        duration: Math.max(1, card.timeout)
        onFinished: {
            if (card.group)
                Notifs.hideGroupPopup(card.group);
            else
                Notifs.hidePopup(card.entry.uid);
        }
    }

    function armCountdown() {
        if (!isPopup || timeout <= 0)
            return;
        progress = 1;
        countdown.restart();
        if (hover.hovered)
            countdown.pause();
    }

    Component.onCompleted: armCountdown()
    onEntryChanged: armCountdown()

    Connections {
        target: Notifs
        function onRefreshed(uid) {
            if (card.entry?.uid === uid)
                card.armCountdown();
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (!countdown.running)
                return;
            if (hovered)
                countdown.pause();
            else
                countdown.resume();
        }
    }

    // ── gestures ──
    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: Notifs.activate(card.entry, card.compact ? null : card.group)
    }
    TapHandler {
        acceptedButtons: Qt.MiddleButton
        onTapped: card.dismiss()
    }
    DragHandler {
        id: drag
        enabled: card.isPopup
        target: card
        xAxis.minimum: 0
        yAxis.enabled: false
        onActiveChanged: {
            if (active)
                return;
            if (card.x > card.width * 0.35)
                swipeOut.start();
            else
                card.x = 0;
        }
    }
    Behavior on x {
        enabled: !drag.active
        NumberAnimation { duration: Theme.durationShort; easing.type: Theme.easeStandard }
    }
    SequentialAnimation {
        id: swipeOut
        NumberAnimation { target: card; property: "x"; to: card.width; duration: Theme.durationShort; easing.type: Theme.easeExit }
        ScriptAction { script: card.dismiss() }
    }

    // ── chrome: critical tint, urgency stripe, countdown line ──
    ClippingRectangle {
        anchors.fill: parent
        radius: card.radius
        color: card.critical ? Theme.alpha(Theme.error, 0.08) : "transparent"

        Rectangle {
            visible: !card.low && !card.compact
            width: 3
            height: parent.height
            color: card.critical ? Theme.error : Theme.accent
        }

        Rectangle {
            visible: card.isPopup && card.timeout > 0
            anchors.bottom: parent.bottom
            height: 2
            width: parent.width * card.progress
            color: card.critical ? Theme.error : Theme.accent
        }
    }

    RowLayout {
        id: layout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.spacingMd
            leftMargin: Theme.spacingMd + (card.low || card.compact ? 0 : 3)
        }
        spacing: Theme.spacingSm

        // ── icon / avatar ──
        Item {
            visible: !card.compact
            Layout.alignment: Qt.AlignTop
            implicitWidth: 40
            implicitHeight: 40

            ClippingRectangle {
                anchors.fill: parent
                radius: Theme.radiusMedium
                color: card.imageSrc !== "" ? "transparent" : card.hashColor(card.appName)

                IconImage {
                    anchors.fill: parent
                    visible: card.imageSrc !== ""
                    source: card.imageSrc
                    implicitSize: 40
                }

                Text {
                    anchors.centerIn: parent
                    visible: card.imageSrc === ""
                    text: (card.appName || "?").charAt(0).toUpperCase()
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLarge
                    font.weight: Theme.weightBold
                    color: Theme.onAccent
                }
            }

            // the app's own icon in the corner when the notification has an image
            IconImage {
                visible: card.hasBoth
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: -3
                implicitSize: 16
                source: card.hasBoth ? Quickshell.iconPath(card.entry.appIcon, true) : ""
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingXs

                Text {
                    Layout.fillWidth: true
                    text: card.entry?.summary ?? ""
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.weightBold
                    color: Theme.textPrimary
                }

                Badge {
                    count: card.compact ? 0 : card.count > 1 ? card.count : 0
                }

                Text {
                    visible: !card.isPopup
                    text: Notifs.relTime(card.entry?.time ?? 0)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.textHint
                }

                // close: a 24px round target, not a bare glyph
                Rectangle {
                    implicitWidth: Theme.hitMin
                    implicitHeight: Theme.hitMin
                    radius: height / 2
                    color: closeArea.containsMouse ? Theme.alpha(Theme.error, 0.18) : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        glyph: Icons.close
                        size: Theme.iconSizeSm
                        color: closeArea.containsMouse ? Theme.error : Theme.textMuted
                    }
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.dismiss()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.entry?.body ?? ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: card.compact ? 2 : 4
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                color: Theme.subtext1
                linkColor: Theme.accent
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Text {
                visible: !card.compact && card.appName !== ""
                text: card.appName
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                color: Theme.textMuted
            }

            // ── action buttons (beyond the implicit default action) ──
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacingXs
                visible: card.actions.length > 0
                spacing: Theme.spacingXs

                Repeater {
                    model: card.actionsExpanded ? card.actions : card.actions.slice(0, 3)

                    Button {
                        required property var modelData
                        compact: true
                        text: modelData.text
                        onClicked: Notifs.invokeAction(card.entry, modelData)
                    }
                }

                Button {
                    visible: !card.actionsExpanded && card.actions.length > 3
                    compact: true
                    glyph: Icons.more
                    onClicked: card.actionsExpanded = true
                }
            }

            // ── inline reply ──
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacingXs
                visible: card.live?.hasInlineReply ?? false
                implicitHeight: 28
                radius: height / 2
                color: Theme.surface1
                border.width: 1
                border.color: reply.activeFocus ? Theme.accent : Theme.outline

                TextInput {
                    id: reply
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingMd
                    anchors.rightMargin: Theme.spacingMd
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.textPrimary
                    onAccepted: {
                        if (text === "" || !card.live)
                            return;
                        card.live.sendInlineReply(text);
                        text = "";
                        Notifs.hidePopupsLike(card.entry);
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.spacingMd
                    visible: reply.text === ""
                    text: card.live?.inlineReplyPlaceholder || "reply…"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    font.italic: true
                    color: Theme.textMuted
                }
            }
        }
    }
}
