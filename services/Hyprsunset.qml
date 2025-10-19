pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple hyprsunset service for controlling blue light filter.
 * Using the kill/launch approach for reliability since hyprctl doesn't always work consistently.
 */
Singleton {
    id: root
    
    // State
    property bool active: false
    property int colorTemperature: 3500
    
    // Fetch initial state on load
    Component.onCompleted: {
        fetchState();
    }
    
    function enable() {
        root.active = true;
        Quickshell.execDetached(["bash", "-c", `pidof hyprsunset || hyprsunset --temperature ${root.colorTemperature}`]);
    }

    function disable() {
        root.active = false;
        Quickshell.execDetached(["bash", "-c", `pkill hyprsunset`]);
    }

    function toggle() {
        if (root.active) {
            root.disable();
        } else {
            root.enable();
        }
    }

    function fetchState() {
        fetchProc.running = true;
    }

    Process {
        id: fetchProc
        running: false
        command: ["bash", "-c", "hyprctl hyprsunset temperature"]
        stdout: StdioCollector {
            id: stateCollector
            onStreamFinished: {
                const output = stateCollector.text.trim();
                if (output.length == 0 || output.startsWith("Couldn't"))
                    root.active = false;
                else
                    root.active = (output != "6500");
            }
        }
    }
    
    // Convenience property for backward compatibility
    readonly property bool nightLightEnabled: active
    
    function toggleNightLight() {
        toggle();
    }
    
    function setTemperature(temp) {
        if (temp < 1000 || temp > 10000) {
            return;
        }
        
        root.colorTemperature = temp;
        
        // If currently enabled, restart with new temperature
        if (active) {
            disable();
            // Small delay before re-enabling
            Qt.callLater(enable);
        }
    }
}
