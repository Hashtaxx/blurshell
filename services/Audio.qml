/**
 * Audio Service Singleton
 * 
 * Provides centralized audio management through PipeWire integration. This service:
 * - Tracks all audio devices (sinks, sources, streams) and application audio nodes
 * - Manages audio device defaults (input/output selection)
 * - Handles volume control with muting, incremental adjustments, and visual feedback
 * - Automatically tracks object state changes for reactive UI updates
 * 
 * Usage: Audio.volume, Audio.toggleMute(), Audio.setDefaultSink(device)
 * Singleton instance ensures single source of truth for system audio state.
 */
pragma Singleton

import qs.settings
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // Partition PipeWire nodes into input devices (sources) and output devices (sinks)
    // Excludes stream nodes (per-application audio) to focus on physical/virtual hardware
    readonly property var nodes: Pipewire.nodes.values.reduce((acc, node) => {
        if (!node.isStream) {
            if (node.isSink)
                acc.outputDevices.push(node);
            else if (node.audio)
                acc.inputDevices.push(node);
        }
        return acc;
    }, {
        inputDevices: [],
        outputDevices: []
    })

    readonly property list<PwNode> outputDevices: nodes.outputDevices
    readonly property list<PwNode> inputDevices: nodes.inputDevices

    // Collect and deduplicate application audio streams (per-app sink nodes)
    // Deduplication ensures each application appears only once despite internal stream multiplexing
    readonly property var appNodes: {
        const nodes = Pipewire.nodes.values.filter((node) => {
            return node.isSink && node.isStream && node.audio;
        });
        
        // Use Set to efficiently track seen node IDs and filter duplicates
        const uniqueNodes = [];
        const seenIds = new Set();
        
        for (const node of nodes) {
            if (!seenIds.has(node.id)) {
                seenIds.add(node.id);
                uniqueNodes.push(node);
            }
        }
        
        return uniqueNodes;
    }

    // Default audio output device (sink) and input device (source)
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // Output (speaker) mute and volume state: 0.0 (silent) to 1.0 (max)
    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property int volumePercent: Math.round(volume * 100)

    // Input (microphone) mute and volume state
    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    // Select appropriate volume icon based on mute state and volume level
    // Returns: mute icon if muted, low/medium/high based on volume thresholds
    readonly property string volumeIcon: {
        if (muted || volume === 0) return Fonts.iconVolumeMute;
        if (volume < 0.33) return Fonts.iconVolumeLow;
        if (volume < 0.66) return Fonts.iconVolumeMedium;
        return Fonts.iconVolumeHigh;
    }

    // Set output volume to specific level (0.0 to 1.0), unmuting if necessary
    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, newVolume));
        }
    }

    // Adjust output volume by delta amount (positive to increase, negative to decrease)
    function adjustVolume(delta: real): void {
        setVolume(volume + delta);
    }

    // Increase output volume by Config.audioIncrement percentage
    function volumeUp(): void {
        adjustVolume(Config.audioIncrement / 100);
    }

    // Decrease output volume by Config.audioIncrement percentage
    function volumeDown(): void {
        adjustVolume(-Config.audioIncrement / 100);
    }

    // Toggle output mute state on or off
    function toggleMute(): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = !muted;
        }
    }

    // Set output mute state explicitly (true = muted, false = unmuted)
    function setMute(mute: bool): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = mute;
        }
    }

    // Set input (source) volume to specific level (0.0 to 1.0), unmuting if necessary
    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(1, newVolume));
        }
    }

    // Change default output device (affects all audio playback)
    function setDefaultSink(newSink: PwNode): void {
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    // Change default input device (affects all audio recording)
    function setDefaultSource(newSource: PwNode): void {
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    // Reactive state tracker: watches all audio devices and streams for changes
    // Ensures UI reactivity when devices connect/disconnect or properties change
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.outputDevices, ...root.inputDevices]
    }
}
