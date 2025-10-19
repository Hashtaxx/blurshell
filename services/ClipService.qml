pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import Quickshell
import Quickshell.Io

// Minimal clipboard history service using the `cliphist` CLI
// Exposes a simple list usable by the UI without extra deps
QtObject {
    id: root

    // Raw lines from `cliphist list` (usually: "<id> <preview text>")
    // Limited to 100 entries for performance
    property list<string> entries: []
    property int maxEntries: 100

    // Timestamp tracking: store when entries were first seen
    property var entryTimestamps: ({})
    property date lastRefreshTime: new Date()

    // Format relative time (e.g., "2m ago", "1h ago", "2d ago")
    function formatTimeAgo(timestamp) {
        if (!timestamp)
            return "Just now";

        var now = new Date();
        var seconds = Math.floor((now - timestamp) / 1000);

        if (seconds < 60)
            return "Just now";

        var minutes = Math.floor(seconds / 60);
        if (minutes < 60)
            return minutes + "m ago";

        var hours = Math.floor(minutes / 60);
        if (hours < 24)
            return hours + "h ago";

        var days = Math.floor(hours / 24);
        if (days < 7)
            return days + "d ago";

        var weeks = Math.floor(days / 7);
        if (weeks < 4)
            return weeks + "w ago";

        var months = Math.floor(days / 30);
        return months + "mo ago";
    }

    // UI-friendly objects
    // - text: content without the leading id or metadata
    // - entry: original line to feed back to cliphist
    // - isImage: heuristic detection for image entries
    // - id, width, height: parsed when available
    // - timestamp: when this entry was first seen
    // - timeAgo: human-readable relative time
    readonly property var preparedEntries: {
        var result = [];
        for (var i = 0; i < entries.length; i++) {
            var line = entries[i];
            var str = String(line);
            var textOnly = str.replace(/^\s*\S+\s+/, "");
            var idMatch = str.match(/^\s*(\d+)/);
            var entryId = idMatch ? idMatch[1] : str;
            var dims = textOnly.match(/(\d+)x(\d+)/);
            var isImage = /\[\[binary data/i.test(textOnly) || /\bimage\//i.test(textOnly) || !!dims;

            // Track timestamp: either use stored timestamp or estimate based on position
            var timestamp = root.entryTimestamps[entryId];
            if (!timestamp) {
                // Estimate: newer entries are at the top, each position = ~1 minute older
                var minutesOld = i * 1;
                timestamp = new Date(root.lastRefreshTime - minutesOld * 60000);
                // Don't modify entryTimestamps during preparedEntries calculation
                // Store it separately to avoid triggering re-evaluation
            }

            result.push({
                text: textOnly,
                entry: str,
                isImage: isImage,
                id: idMatch ? parseInt(idMatch[1]) : 0,
                width: dims ? parseInt(dims[1]) : 0,
                height: dims ? parseInt(dims[2]) : 0,
                timestamp: timestamp,
                timeAgo: root.formatTimeAgo(timestamp)
            });
        }
        return result;
    }

    // Escape a string for safe inclusion inside single quotes in a shell command
    function shellSingleQuoteEscape(s) {
        return String(s).replace(/'/g, "'\\''");
    }

    // Copy a specific history entry back into the clipboard (decoding if needed)
    function copy(entry) {
        // Use bash for the small pipeline
        Quickshell.execDetached(["bash", "-c", `echo '${shellSingleQuoteEscape(entry)}' | cliphist decode | wl-copy`]);
    }

    // Delete a specific entry from history
    function deleteEntry(entry) {
        // Extract the ID from the entry string
        var idMatch = String(entry).match(/^\s*(\d+)/);
        if (idMatch) {
            var entryId = idMatch[1];
            Quickshell.execDetached(["bash", "-c", `cliphist delete ${entryId}`]);
            // Optimistically update and schedule a refresh
            root.delayedUpdateTimer.restart();
        }
    }

    // Wipe the entire history and clear current clipboards
    function clearAll() {
        Quickshell.execDetached(["bash", "-c",
            // Try native wipe, fallback to deleting all ids if unavailable; also clear clipboard + primary
            "cliphist wipe || (cliphist list | awk '{print $1}' | xargs -r cliphist delete); wl-copy -c; wl-copy -pc"]);
        // Optimistically clear UI and schedule a refresh
        root.entries = [];
        root.delayedUpdateTimer.restart();
    }

    // Trigger a refresh from cliphist
    function refresh() {
        // Don't start a new refresh if one is already running
        if (readProc.running) return;
        
        root.lastRefreshTime = new Date();
        readProc.buffer = [];
        readProc.running = true;
    }

    // Update when the clipboard text changes (helps keep history fresh)
    property var _clipConn: Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            root.delayedUpdateTimer.restart();
        }
    }

    property var delayedUpdateTimer: Timer {
        interval: 150   // small debounce to avoid races
        repeat: false
        onTriggered: root.refresh()
    }

    // Read the history via `cliphist list`
    property var readProc: Process {
        property list<string> buffer: []

        command: ["cliphist", "list"]

        stdout: SplitParser {
            onRead: line => root.readProc.buffer.push(line)
        }

        onStarted: {
            // Clear buffer when process starts to avoid accumulation
            root.readProc.buffer = [];
        }

        onRunningChanged: {
            if (!running) {
                // Accept the latest buffer when process stops (limited to maxEntries)
                var newEntries = root.readProc.buffer.slice(0, root.maxEntries);
                
                // Update timestamps for new entries before setting the entries property
                var newTimestamps = Object.assign({}, root.entryTimestamps);
                for (var i = 0; i < newEntries.length; i++) {
                    var str = String(newEntries[i]);
                    var idMatch = str.match(/^\s*(\d+)/);
                    var entryId = idMatch ? idMatch[1] : str;
                    
                    if (!newTimestamps[entryId]) {
                        // Estimate: newer entries are at the top, each position = ~1 minute older
                        var minutesOld = i * 1;
                        newTimestamps[entryId] = new Date(root.lastRefreshTime - minutesOld * 60000);
                    }
                }
                
                // Update both properties together to avoid intermediate states
                root.entryTimestamps = newTimestamps;
                root.entries = newEntries;
            }
        }
    }

    // Copy entry to clipboard and paste it after a short delay
    function copyAndPaste(entry) {
        // First, copy the entry to clipboard using cliphist decode
        Quickshell.execDetached(["bash", "-c", `echo '${shellSingleQuoteEscape(entry)}' | cliphist decode | wl-copy`]);

        // Wait briefly for clipboard to update, then paste
        Quickshell.execDetached(["bash", "-c", "sleep 0.1; wtype -M ctrl v -m ctrl"]);
    }

    // Just copy without pasting
    function copyOnly(entry) {
        Quickshell.execDetached(["bash", "-c", `echo '${shellSingleQuoteEscape(entry)}' | cliphist decode | wl-copy`]);
    }
}
