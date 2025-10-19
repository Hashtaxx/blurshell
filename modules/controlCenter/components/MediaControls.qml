pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Mpris
import qs.settings
import qs.components
import qs.components.animations
import qs.services

/*
 MediaControls.qml — Control center media widget

 Quick summary:
 - Shows album art, track title/artist/album, source name and playback controls.
 - Integrates with the MediaService (MPRIS) singleton used across the project.
 - Supports play/pause, previous/next, and click-to-seek on the progress bar.

 Notes:
 - Firefox MPRIS may keep position across autoplayed videos. Clients should
     reset position when metadata (e.g. title) changes. See Bugzilla #1979495.
 - Keep UI logic lightweight; heavy logic belongs in the MediaService backend.
*/
Rectangle {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: hasActivePlayer ? (playerColumn.implicitHeight + 32) : 0
    visible: hasActivePlayer

    color: Colors.darken_20
    radius: 16

    // Bound properties from MediaService for current active player
    property var activePlayer: MediaService.activePlayer
    property bool hasActivePlayer: MediaService.hasActivePlayer
    property bool isPlaying: MediaService.isPlaying
    property real displayPosition: MediaService.displayPosition
    property real displayLength: MediaService.displayLength

    // Derived value: fraction of progress (0.0 - 1.0). Keeps progress math in one place.
    readonly property real progressFraction: {
        if (!activePlayer || !activePlayer.lengthSupported)
            return 0;
        const len = displayLength;
        if (!isFinite(len) || len <= 0)
            return 0;
        return Math.min(1, Math.max(0, displayPosition / len));
    }

    AnimatedHeight on Layout.preferredHeight {
        enabled: true
    }

    AnimatedOpacity on opacity {}

    Column {
        id: playerColumn
        anchors.fill: parent
        anchors {
            topMargin: 12
            rightMargin: 12
            bottomMargin: 6
            leftMargin: 12
        }
        spacing: 18

        Item {
            width: parent.width
            height: albumArtSize

            readonly property int albumArtSize: 80

            Rectangle {
                id: albumArtContainer
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.albumArtSize
                height: parent.albumArtSize
                radius: 12
                color: Colors.brighten_10
                clip: true

                Image {
                    id: albumArt
                    property int radius: 8
                    anchors.fill: parent
                    source: root.activePlayer?.trackArtUrl || ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    visible: source != ""
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        id: opacityMaskInstance
                        maskSource: Rectangle {
                            id: maskedRect
                            width: albumArt.width
                            height: albumArt.height
                            radius: albumArt.radius
                        }
                    }
                }

                // Fallback icon when no album art is available
                Text {
                    anchors.centerIn: parent
                    text: Fonts.iconMusic
                    font.family: Fonts.iconFont
                    font.pixelSize: 36
                    color: Colors.textSubdued
                    visible: albumArt.source == ""
                }
            }

            Column {
                id: trackInfoColumn
                anchors {
                    left: albumArtContainer.right
                    leftMargin: 12
                    right: playButton.left
                    rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                spacing: 4

                Text {
                    id: trackName
                    width: parent.width
                    text: root.activePlayer?.trackTitle || "No track"
                    color: Colors.text
                    font.pixelSize: Fonts.h5
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
                }

                Text {
                    id: artistName
                    width: parent.width
                    text: root.activePlayer?.trackArtist || ""
                    color: Colors.textSubdued
                    font.pixelSize: Fonts.p
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    visible: text !== ""
                    wrapMode: Text.NoWrap
                }

                Text {
                    id: albumName
                    width: parent.width
                    text: root.activePlayer?.trackAlbum || ""
                    color: Colors.textSubdued
                    font.pixelSize: Fonts.p - 2
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    visible: text !== ""
                    wrapMode: Text.NoWrap
                }

                Text {
                    id: sourceName
                    width: parent.width
                    text: root.activePlayer?.identity || ""
                    color: Colors.textSubdued
                    font.pixelSize: Fonts.p - 4
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    visible: text !== ""
                    wrapMode: Text.NoWrap
                }
            }

            ActionButton {
                id: playButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: {
                    if (!root.activePlayer)
                        return Fonts.iconPlay;
                    return root.isPlaying ? Fonts.iconPause : Fonts.iconPlay;
                }
                width: 48
                height: 48
                backgroundColor: Config.controlCenterAccent
                borderColor: Config.controlCenterAccent
                textColor: Colors.bg
                enabled: root.activePlayer?.canTogglePlaying || false
                onClicked: {
                    if (root.activePlayer && root.activePlayer.canTogglePlaying) {
                        root.activePlayer.togglePlaying();
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: (previousButton.visible || nextButton.visible) ? 36 : 20
            visible: root.activePlayer?.positionSupported || false

            // Progress row: previous button, progress bar (click-to-seek), next button
            ActionButton {
                id: previousButton
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                icon: Fonts.iconBackward
                width: 36
                height: 36
                enabled: root.activePlayer?.canGoPrevious || false
                visible: root.activePlayer?.canGoPrevious || false
                backgroundColor: "transparent"
                borderColor: "transparent"
                textColor: Colors.text
                onClicked: {
                    if (root.activePlayer && root.activePlayer.canGoPrevious) {
                        root.activePlayer.previous();
                    }
                }
            }

            Rectangle {
                anchors.left: previousButton.visible ? previousButton.right : parent.left
                anchors.leftMargin: previousButton.visible ? 12 : 0
                anchors.right: nextButton.visible ? nextButton.left : parent.right
                anchors.rightMargin: nextButton.visible ? 12 : 0
                anchors.verticalCenter: parent.verticalCenter
                height: 10
                radius: height
                color: Colors.brighten_10

                // Progress indicator width is computed from root.progressFraction
                Rectangle {
                    height: parent.height
                    width: root.progressFraction * parent.width
                    radius: parent.radius
                    color: Config.controlCenterAccent

                    // AnimatedWidth is provided by qs.components.animations; keep it here
                    AnimatedWidth on width {}
                }

                MouseArea {
                    anchors.fill: parent
                    // Only enable seeking if the player supports it
                    enabled: root.activePlayer?.canSeek || false
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: mouse => {
                        if (!root.activePlayer || !root.activePlayer.canSeek || !root.activePlayer.lengthSupported)
                            return;

                        // Compute ratio relative to the progress track width
                        const ratio = Math.min(1, Math.max(0, mouse.x / width));
                        const newPosition = ratio * root.activePlayer.length;
                        // Update player position and the displayed position
                        root.activePlayer.position = newPosition;
                        root.displayPosition = newPosition;
                    }
                }
            }

            ActionButton {
                id: nextButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: Fonts.iconForward
                width: 36
                height: 36
                enabled: root.activePlayer?.canGoNext || false
                visible: root.activePlayer?.canGoNext || false
                backgroundColor: "transparent"
                borderColor: "transparent"
                textColor: Colors.text
                onClicked: {
                    if (root.activePlayer && root.activePlayer.canGoNext) {
                        root.activePlayer.next();
                    }
                }
            }
        }
    }
}
