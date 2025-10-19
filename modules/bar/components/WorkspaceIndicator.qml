pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.settings
import qs.components.animations

Background {
    id: root
    
    signal workspaceClicked(int workspaceId)
    
    // Constants for visual consistency
    readonly property int dotSpacing: 0
    readonly property int separatorSpacing: 4
    readonly property int separatorWidth: 2
    
    // Build visible workspaces list from collected data
    readonly property var visibleWorkspacesData: {
        const data = [];
        const workspaceRules = Config.workspaceRules || {};
        const wsInfo = workspaceInstantiator.workspaceInfo;
        
        // Force re-evaluation when updateCounter changes
        workspaceInstantiator.updateCounter;
        
        // Sort screens by x position to match monitor layout
        const sortedScreens = [...Quickshell.screens].sort((a, b) => a.x - b.x);
        
        // Process each monitor
        for (const screen of sortedScreens) {
            const monitorName = screen.name;
            const ruleWorkspaces = workspaceRules[monitorName] || [];
            
            // Only process monitors with defined workspace rules
            if (ruleWorkspaces.length === 0) continue;
            
            // Collect workspaces for this monitor - ONLY from rules or those assigned to this monitor
            const monitorWorkspaces = [];
            
            for (const ruleWsId of ruleWorkspaces) {
                const wsInfoEntry = wsInfo[ruleWsId];
                monitorWorkspaces.push({
                    id: ruleWsId,
                    hasWindows: wsInfoEntry ? wsInfoEntry.hasWindows : false
                });
            }
            
            // Sort by ID
            monitorWorkspaces.sort((a, b) => a.id - b.id);
            
            // Filter visible workspaces: all with windows + first empty one
            const visibleWorkspaces = [];
            let hasEmptyWorkspace = false;
            
            for (const ws of monitorWorkspaces) {
                if (ws.hasWindows) {
                    visibleWorkspaces.push(ws.id);
                } else if (!hasEmptyWorkspace) {
                    visibleWorkspaces.push(ws.id);
                    hasEmptyWorkspace = true;
                }
            }
            
            // DON'T add "new workspace" button - only show predefined workspaces
            
            if (visibleWorkspaces.length > 0) {
                data.push({
                    monitorName: monitorName,
                    workspaces: visibleWorkspaces
                });
            }
        }
        
        return data;
    }
    
    // Collect workspace information reactively
    Instantiator {
        id: workspaceInstantiator
        model: Hyprland.workspaces
        
        property var workspaceInfo: ({})
        property int updateCounter: 0  // Trigger to force re-evaluation
        
        delegate: Item {
            id: workspaceItem
            required property var modelData
            
            readonly property int wsId: modelData.id
            readonly property string wsMonitorName: modelData.monitor ? modelData.monitor.name : ""
            
            // Count toplevels
            property int toplevelCount: 0
            
            Repeater {
                model: workspaceItem.modelData.toplevels
                delegate: Item {
                    Component.onCompleted: workspaceItem.toplevelCount++
                    Component.onDestruction: workspaceItem.toplevelCount--
                }
            }
            
            readonly property bool hasWindows: toplevelCount > 0
            
            // Track if this workspace is currently visible on its monitor
            readonly property bool isVisibleOnMonitor: modelData.monitor ? 
                modelData.monitor.activeWorkspace === modelData : false
            
            // Update workspace info when relevant properties change
            function updateInfo() {
                const info = Object.assign({}, workspaceInstantiator.workspaceInfo);
                info[wsId] = {
                    monitorName: wsMonitorName,
                    hasWindows: hasWindows,
                    isVisibleOnMonitor: isVisibleOnMonitor
                };
                workspaceInstantiator.workspaceInfo = info;
                workspaceInstantiator.updateCounter++;  // Trigger re-evaluation
            }
            
            Component.onCompleted: updateInfo()
            onHasWindowsChanged: updateInfo()
            onWsMonitorNameChanged: updateInfo()
            onIsVisibleOnMonitorChanged: updateInfo()
        }
    }
    
    Row {
        id: workspaceDotsRow
        anchors.centerIn: parent
        spacing: 0
        
        Repeater {
            model: root.visibleWorkspacesData
            
            delegate: Item {
                id: monitorGroup
                required property var modelData
                required property int index
                
                // Calculate width based on content
                readonly property int dotWidth: root.height
                readonly property int totalDots: modelData.workspaces.length
                readonly property bool isLastMonitor: index >= root.visibleWorkspacesData.length - 1
                
                width: (dotWidth * totalDots) + 
                       (isLastMonitor ? 0 : root.separatorSpacing * 2 + root.separatorWidth)
                height: root.height
                
                // Workspace dots for this monitor
                Row {
                    anchors.left: parent.left
                    spacing: root.dotSpacing
                    height: parent.height
                    
                    Repeater {
                        model: monitorGroup.modelData.workspaces
                        
                        delegate: MouseArea {
                            id: workspaceDelegate
                            required property int modelData
                            
                            width: monitorGroup.dotWidth
                            height: root.height
                            hoverEnabled: true
                            
                            readonly property int workspaceId: modelData
                            readonly property bool hasWindows: 
                                (workspaceInstantiator.workspaceInfo[workspaceId]?.hasWindows || false)
                            readonly property bool isVisibleOnMonitor:
                                (workspaceInstantiator.workspaceInfo[workspaceId]?.isVisibleOnMonitor || false)
                            
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                // Only switch to predefined workspaces
                                Hyprland.dispatch("workspace " + workspaceId);
                                root.workspaceClicked(workspaceId);
                            }
                            
                            Rectangle {
                                anchors.centerIn: parent
                                color: {
                                    if (workspaceDelegate.isVisibleOnMonitor) {
                                        // Currently visible on monitor - full opacity
                                        return Colors.text;
                                    } else if (workspaceDelegate.hasWindows) {
                                        // Non-visible with windows - medium opacity
                                        return Qt.alpha(Colors.text, 0.85);
                                    } else {
                                        // Empty workspace - dimmed
                                        return Qt.alpha(Colors.text, 0.4);
                                    }
                                }
                                width: height
                                height: parent.height / 1.5
                                radius: height / 2
                                
                                scale: {
                                    if (workspaceDelegate.isVisibleOnMonitor) return 0.9;
                                    if (workspaceDelegate.containsMouse) return 0.8;
                                    return 0.7;
                                }
                                
                                AnimatedScale on scale {
                                }
                                
                                AnimatedColor on color {
                                }
                            }
                        }
                    }
                }
                
                // Separator between monitors
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: root.separatorSpacing
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.separatorWidth
                    height: root.height / 2
                    color: Qt.alpha(Colors.text, 0.3)
                    radius: 1
                    visible: !monitorGroup.isLastMonitor
                }
            }
        }
    }
}
