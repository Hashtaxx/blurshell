pragma Singleton

// NOTE: Firefox + YouTube MPRIS Bug (as of 2025-10)
//
// When playing YouTube videos in Firefox, the MPRIS interface does NOT reset
// the "position" property when a new video starts (especially during autoplay).
// This means Mpris.players.values.position may continue increasing from the
// previous video instead of resetting to 0.
//
// The issue is upstream in Firefox’s MPRIS implementation (Bugzilla #1979495)
// and not a Quickshell or QML bug. YouTube Music and other players usually work
// correctly.

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // All available MPRIS players
    property var players: Mpris.players

    // Active player selection logic
    property var activePlayer: {
        const playerList = players?.values ?? [];

        // First try to find a playing player
        const playingPlayer = playerList.find(player => player.playbackState === MprisPlaybackState.Playing);

        if (playingPlayer)
            return playingPlayer;

        // Otherwise return the first available player
        return playerList[0] ?? null;
    }

    // Convenience properties
    property bool hasActivePlayer: activePlayer !== null
    property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing || false

    // Display values for smooth position updates
    property real displayPosition: activePlayer?.position || 0
    property real displayLength: activePlayer?.length || 1

    // Timer for smooth position updates when playing
    Timer {
        id: positionTimer
        interval: 1000
        repeat: true
        running: root.isPlaying && root.activePlayer?.positionSupported || false

        onTriggered: {
            if (root.activePlayer) {
                root.displayPosition = root.activePlayer.position;
            }
        }
    }

    // Update displayPosition when track changes or player changes
    onActivePlayerChanged: {
        if (activePlayer) {
            displayPosition = activePlayer.position;
            displayLength = activePlayer.length;
        }
    }

    // Connect to track changes
    Connections {
        target: root.activePlayer

        function onTrackChanged() {
            if (root.activePlayer) {
                root.displayPosition = root.activePlayer.position;
                root.displayLength = root.activePlayer.length;
            }
        }

        function onPositionChanged() {
            if (root.activePlayer) {
                root.displayPosition = root.activePlayer.position;
            }
        }

        function onLengthChanged() {
            if (root.activePlayer) {
                root.displayLength = root.activePlayer.length;
            }
        }
    }
}
