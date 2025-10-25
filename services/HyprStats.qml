pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.settings

Singleton {
    id: root

    property var workspaceRules: ({})
    property string splash: ""    
    // TopLevel Window
    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel?.wayland?.activated ? Hyprland.activeToplevel : null
    // Workspaces
    readonly property var workspaces: Hyprland.workspaces
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    // Emitted when monitors are added/removed
    signal monitorConfigChanged(string eventName)


    // Initialize on component creation
    Component.onCompleted: {
        // Load workspace rules from config if available
        if (Config.ready && Config.workspaceRules && Object.keys(Config.workspaceRules).length > 0) {
            root.workspaceRules = Config.workspaceRules;
        } else {
            refreshWorkspaceRules();
        }
    }

    // Refresh workspace rules
    function refreshWorkspaceRules() {
        getWorkspaceRules.running = true;
        getSplash.running = true;
    }

    // Get workspace rules
    Process {
        id: getWorkspaceRules
        running: true
        command: ["hyprctl", "workspacerules"]
        stdout: StdioCollector {
            id: workspaceRulesCollector
            onStreamFinished: {
                try {
                    const text = workspaceRulesCollector.text;
                    const lines = text.split('\n');
                    let currentWorkspace = null;
                    let currentMonitor = null;
                    let rulesByMonitor = {};
                    
                    for (let i = 0; i < lines.length; i++) {
                        const line = lines[i];
                        
                        // Match workspace rule header with number (e.g., "Workspace rule 1:")
                        const wsMatch = line.match(/^Workspace rule (\d+):/);
                        if (wsMatch) {
                            currentWorkspace = parseInt(wsMatch[1]);
                            currentMonitor = null;
                            continue;
                        }
                        
                        // Match monitor line
                        const monitorMatch = line.match(/^\s*monitor:\s*(.+)$/);
                        if (monitorMatch && currentWorkspace !== null) {
                            currentMonitor = monitorMatch[1].trim();
                            
                            // Only add if monitor is set (not <unset>)
                            if (currentMonitor !== "<unset>" && currentMonitor !== "") {
                                if (!rulesByMonitor[currentMonitor]) {
                                    rulesByMonitor[currentMonitor] = [];
                                }
                                rulesByMonitor[currentMonitor].push(currentWorkspace);
                            }
                            currentWorkspace = null;
                        }
                    }
                    
                    // Sort workspace arrays for each monitor
                    for (let monitor in rulesByMonitor) {
                        rulesByMonitor[monitor].sort((a, b) => a - b);
                    }
                    
                    root.workspaceRules = rulesByMonitor;
                    
                    // Save to config for persistence
                    saveWorkspaceRulesToConfig();
                } catch (e) {
                    console.error("Error parsing workspace rules:", e);
                }
            }
        }
    }

    // Save workspace rules to config file
    function saveWorkspaceRulesToConfig() {
        if (!Config.ready) {
            console.warn("Config not ready yet, skipping workspace rules save");
            return;
        }
        
        // Helper function to create a sorted JSON string for comparison
        function sortedStringify(obj) {
            if (typeof obj !== 'object' || obj === null) return JSON.stringify(obj);
            if (Array.isArray(obj)) return JSON.stringify(obj);
            
            // Sort object keys and create a new object with sorted keys
            const sortedObj = {};
            Object.keys(obj).sort().forEach(key => {
                sortedObj[key] = obj[key];
            });
            return JSON.stringify(sortedObj);
        }
        
        // Only save if workspace rules have changed
        const currentRulesJson = sortedStringify(root.workspaceRules);
        const configRulesJson = sortedStringify(Config.workspaceRules);
        
        if (currentRulesJson !== configRulesJson) {
            Config.set.workspaceRules = root.workspaceRules;
            console.log("Workspace rules saved to config");
        }
    }

    // Get splash text
    Process {
        id: getSplash
        running: true
        command: ["hyprctl", "splash"]
        stdout: StdioCollector {
            id: splashCollector
            onStreamFinished: {
                root.splash = splashCollector.text.trim();
            }
        }
    }

    // Listen to Hyprland events and update accordingly
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const n = event.name;
            
            // Skip v2 events
            if (n.endsWith("v2"))
                return;

            if (["workspace", "moveworkspace", "activespecial", "focusedmon", "openwindow", "closewindow", "movewindow"].includes(n)) {
            Hyprland.refreshWorkspaces();
            Hyprland.refreshToplevels();
            }
            // Workspace-specific events: refresh workspaces only
            else if (n.includes("workspace")) {
            Hyprland.refreshWorkspaces();
            }
            // Window-related events: refresh toplevels only
            else if (n.includes("window") || n.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(n)) {
            Hyprland.refreshToplevels();
            } 
            // Monitor configuration changed (hot-plug/unplug or suspend/resume)
            else if (n === "monitoradded" || n === "monitorremoved") {
                root.monitorConfigChanged(n);
            }
            else if (n === "configreloaded") {
                // When Hyprland config is reloaded, workspace rules may have changed
                console.log("Hyprland config reloaded, refreshing workspace rules and reloading components...");
                refreshWorkspaceRules();
                // Delay the reload slightly to let other events settle
                reloadDelayTimer.start();
            }
        }
    }

    Timer {
        id: reloadDelayTimer
        interval: 500
        repeat: false
        running: false
        onTriggered: {
            Quickshell.reload(false);
        }
    }
}
