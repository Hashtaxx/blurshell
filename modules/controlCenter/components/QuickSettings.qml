pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.settings
import qs.services
import qs.components
import qs.components.animations
import qs.modules.controlCenter.components

/**
 * QuickSettings.qml
 * 
 * Provides a grid of interactive quick-action bubbles for system controls including WiFi,
 * Bluetooth, volume, power modes, night light, and wallpaper switching. Supports two states:
 * overview (grid of all bubbles) and expanded (single bubble with detailed controls).
 * 
 * Grid automatically calculates square cells based on available width. When a bubble expands,
 * all other bubbles fade out and the expanded content takes over the space.
 */
Item {
    id: root
    
    property int spacing: 8
    readonly property int columns: 5
    readonly property int rows: 2
    readonly property real cellSize: (width - (columns - 1) * spacing) / columns
    
    property string expandedBubbleId: ""
    readonly property bool isExpanded: expandedBubbleId !== ""
    property Component expandedContentComponent: null
    property real expandedHeight: 600
    
    signal expandedStateChanged(bool expanded)
    
    implicitWidth: gridContainer.implicitWidth
    implicitHeight: gridContainer.implicitHeight
    
    function expandBubble(bubbleId: string, bubble: var): void {
        // Trigger parent animation readiness before state transition
        if (parent && parent.animationsReady !== undefined) {
            parent.animationsReady = true;
        }
        
        root.expandedBubbleId = bubbleId;
        root.expandedContentComponent = bubble.expandedContent;
        root.expandedHeight = bubble.expandedHeight;
        root.expandedStateChanged(true);
    }
    
    function collapseAll(): void {
        root.expandedBubbleId = "";
        root.expandedContentComponent = null;
        root.expandedHeight = 600;
        root.expandedStateChanged(false);
        Bluetooth.stopDiscovery();
    }
    
    GridLayout {
        id: gridContainer
        anchors.fill: parent
        
        columns: root.columns
        rows: root.rows
        columnSpacing: root.spacing
        rowSpacing: root.spacing
        
        Bubble {
            id: wifiBubble
            Layout.column: 0
            Layout.row: 0
            Layout.columnSpan: 2
            Layout.fillHeight: true
            Layout.preferredWidth: root.cellSize * 2 + root.spacing
            Layout.preferredHeight: root.cellSize
            
            orientation: "horizontal"
            icon: Network.wifiIcon
            isActive: Network.wifiEnabled && Network.wifi
            label: "WiFi"
            sublabel: Network.wifiEnabled ? (Network.activeNetwork?.ssid ?? "No Connection") : "Off"
            
            expanded: root.expandedBubbleId === "wifi"
            visible: !root.isExpanded || expanded
            opacity: !root.isExpanded ? 1.0 : (expanded ? 1.0 : 0.0)
            
            AnimatedOpacity on opacity {}
            
            onQuickActionClicked: {
                Network.toggleWifi();
            }
            
            onExpandClicked: {
                root.expandBubble("wifi", wifiBubble);
                if (Network.wifiEnabled) {
                    Network.rescanWifi();
                }
            }
            
            expandedContent: Component {
                WifiExpanded {
                }
            }
        }
        
        Bubble {
            id: bluetoothBubble
            Layout.column: 2
            Layout.row: 0
            Layout.columnSpan: 2
            Layout.fillHeight: true
            Layout.preferredWidth: root.cellSize * 2 + root.spacing
            Layout.preferredHeight: root.cellSize
            
            orientation: "horizontal"
            icon: Bluetooth.bluetoothIcon
            isActive: Bluetooth.enabled
            label: "BT"
            sublabel: Bluetooth.enabled ? (Bluetooth.hasConnectedDevices ? (Bluetooth.firstConnectedDeviceName + (Bluetooth.connectedDeviceCount > 1 ? " +" + (Bluetooth.connectedDeviceCount - 1) : "")) : "On") : "Off"
            
            expanded: root.expandedBubbleId === "bluetooth"
            visible: !root.isExpanded || expanded
            opacity: !root.isExpanded ? 1.0 : (expanded ? 1.0 : 0.0)
            

            AnimatedOpacity on opacity {}
            
            onQuickActionClicked: {
                Bluetooth.toggleBluetooth();
            }
            
            onExpandClicked: {
                root.expandBubble("bluetooth", bluetoothBubble);
                if (Bluetooth.enabled) {
                    Bluetooth.startDiscovery();
                    Bluetooth.setDiscoverable(true);
                    Bluetooth.setPairable(true);
                }
            }
            
            expandedContent: Component {
                BluetoothExpanded {
                }
            }
        }
        
        Bubble {
            id: volumeBubble
            Layout.column: 4
            Layout.row: 0
            Layout.rowSpan: 2
            Layout.fillHeight: true
            Layout.preferredWidth: root.cellSize
            Layout.preferredHeight: root.cellSize * 2 + root.spacing
            
            orientation: "vertical"
            icon: Audio.volumeIcon
            isActive: !Audio.muted
            disabledBackground: Colors.red
            disabledBorder: Colors.red
            disabledText: Colors.textSecondary
            label: ""
            sublabel: ""
            
            showMeter: true
            meterLevel: Audio.volume
            meterColor: Config.controlCenterAccent
            
            expanded: root.expandedBubbleId === "volume"
            visible: !root.isExpanded || expanded
            opacity: !root.isExpanded ? 1.0 : (expanded ? 1.0 : 0.0)
            

            AnimatedOpacity on opacity {}
            
            onQuickActionClicked: {
                Audio.toggleMute();
            }
            
            onExpandClicked: {
                root.expandBubble("volume", volumeBubble);
            }
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                z: 100
                
                onWheel: (wheel) => {
                    if (Audio.muted) {
                        wheel.accepted = true;
                        return;
                    }
                    const delta = (wheel.angleDelta.y / 120) * 0.025;
                    Audio.adjustVolume(delta);
                    wheel.accepted = true;
                }
            }
            
            expandedContent: Component {
                VolumeExpanded {
                }
            }
        }
        
        Bubble {
            id: powerModeBubble
            Layout.column: 0
            Layout.row: 1
            Layout.columnSpan: 2
            Layout.fillHeight: true
            Layout.preferredWidth: root.cellSize * 2 + root.spacing
            Layout.preferredHeight: root.cellSize
            
            orientation: "horizontal"
            icon: Power.currentProfileIcon
            isActive: true
            label: "Power"
            sublabel: Power.currentProfileName
            expandedHeight: 300
            
            expanded: root.expandedBubbleId === "powermode"
            visible: !root.isExpanded || expanded
            opacity: !root.isExpanded ? 1.0 : (expanded ? 1.0 : 0.0)
            

            AnimatedOpacity on opacity {}
            
            onQuickActionClicked: {
                Power.cycleProfile();
            }
            
            onExpandClicked: {
                root.expandBubble("powermode", powerModeBubble);
            }
            
            expandedContent: Component {
                PowerModeExpanded {
                }
            }
        }
        
        Item {
            Layout.column: 2
            Layout.row: 1
            Layout.fillHeight: true
            Layout.preferredWidth: root.cellSize
            Layout.preferredHeight: root.cellSize
            
            visible: !root.isExpanded
            opacity: !root.isExpanded ? 1.0 : 0.0
            
            AnimatedOpacity on opacity {}
            
            ActionButton {
                id: nightLightButton
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                
                icon: Hyprsunset.nightLightEnabled ? Fonts.iconLightNight : Fonts.iconLightOff
                backgroundColor: Hyprsunset.nightLightEnabled ? Config.controlCenterAccent : Colors.darken_20
                borderColor: Hyprsunset.nightLightEnabled ? Config.controlCenterAccent : Colors.darken_20
                textColor: Hyprsunset.nightLightEnabled ? Colors.textSecondary : Colors.text

                AnimatedColor on backgroundColor {}
                AnimatedColor on borderColor {}
                
                onClicked: {
                    Hyprsunset.toggleNightLight();
                }
            }
        }
        
        Item {
            Layout.column: 3
            Layout.row: 1
            Layout.fillHeight: true
            Layout.preferredWidth: root.cellSize
            Layout.preferredHeight: root.cellSize
            
            visible: !root.isExpanded
            opacity: !root.isExpanded ? 1.0 : 0.0
            
            AnimatedOpacity on opacity {}
            
            ActionButton {
                id: nextWallpaperButton
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                
                icon: Fonts.iconWallpaperNext
                backgroundColor: Config.controlCenterAccent
                borderColor: Config.controlCenterAccent
                textColor: Colors.textSecondary
                loading: WallpaperService.isTransitioning
                enabled: WallpaperService.useWallpaperDirectory && !WallpaperService.isTransitioning && WallpaperService.queueLength > 1
                
                onClicked: {
                    WallpaperService.nextWallpaper();
                }
            }
        }
    }
}
