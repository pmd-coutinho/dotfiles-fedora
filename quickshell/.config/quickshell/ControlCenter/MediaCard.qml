// Now playing: art, title/artist, transport, a seekable progress bar. Hidden
// when no player is around. The player is Services/Media.qml's shared pick, so
// this and the bar widget always control the same thing.
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.Components
import qs.Services
import qs.Theme

Rectangle {
    id: card

    readonly property var p: Media.player
    readonly property bool seekable: p !== null && p.positionSupported && p.lengthSupported && p.length > 0

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        const m = Math.floor(s / 60);
        const r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }

    visible: p !== null
    implicitHeight: body.implicitHeight + 2 * Theme.spacingSm
    radius: Theme.radiusMedium
    color: Theme.surfaceRaised

    // MPRIS position doesn't tick by itself: poke it once a second while playing
    Timer {
        interval: 1000
        repeat: true
        running: card.visible && (card.p?.isPlaying ?? false)
        onTriggered: card.p?.positionChanged()
    }

    ColumnLayout {
        id: body
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.spacingSm
        }
        spacing: Theme.spacingSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSm

            ClippingRectangle {
                implicitWidth: 64
                implicitHeight: 64
                radius: Theme.radiusMedium
                color: Theme.surface1

                Image {
                    id: art
                    anchors.fill: parent
                    source: card.p?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(128, 128)
                }

                Icon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    glyph: Icons.music
                    size: Theme.iconSizeXl
                    color: Theme.textMuted
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: card.p?.trackTitle || (card.p?.identity ?? "")
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.weightBold
                    color: Theme.textPrimary
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.p?.trackArtist ?? ""
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    color: Theme.textSecondary
                }

                Text {
                    Layout.fillWidth: true
                    text: card.p?.identity ?? ""
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.textHint
                }

                RowLayout {
                    Layout.topMargin: 2
                    spacing: Theme.spacingXs

                    Button {
                        compact: true
                        glyph: Icons.previous
                        enabled: card.p?.canGoPrevious ?? false
                        onClicked: card.p?.previous()
                    }
                    Button {
                        compact: true
                        kind: "primary"
                        glyph: (card.p?.isPlaying ?? false) ? Icons.pause : Icons.play
                        enabled: card.p?.canTogglePlaying ?? false
                        onClicked: card.p?.togglePlaying()
                    }
                    Button {
                        compact: true
                        glyph: Icons.next
                        enabled: card.p?.canGoNext ?? false
                        onClicked: card.p?.next()
                    }

                    Item { Layout.fillWidth: true }

                    // only when more than one player is around; the card
                    // otherwise silently picked an arbitrary one
                    Button {
                        visible: Media.players.length > 1
                        compact: true
                        glyph: Icons.playlist
                        onClicked: Media.cycle()
                    }
                    Button {
                        visible: card.p?.canRaise ?? false
                        compact: true
                        glyph: Icons.raise
                        onClicked: {
                            card.p?.raise();
                            Notifs.panelOpen = false;
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: card.seekable
            spacing: Theme.spacingSm

            Text {
                text: card.fmt(card.p?.position ?? 0)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTiny
                color: Theme.textHint
            }

            SliderBar {
                Layout.fillWidth: true
                thickness: 4
                interactive: card.p?.canSeek ?? false
                value: card.seekable ? (card.p.position / card.p.length) : 0
                color: Theme.pink
                onMoved: v => { if (card.p) card.p.position = v * card.p.length; }
            }

            Text {
                text: card.fmt(card.p?.length ?? 0)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTiny
                color: Theme.textHint
            }
        }
    }
}
