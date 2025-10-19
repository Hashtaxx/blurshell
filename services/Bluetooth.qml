pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import qs.settings

/**
 * Bluetooth service using Quickshell Bluetooth API.
 * Provides access to Bluetooth adapter and device management.
 */
Singleton {
    id: root

    // ===== Adapter State =====
    
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property bool discovering: Bluetooth.defaultAdapter?.discovering ?? false
    readonly property bool pairable: Bluetooth.defaultAdapter?.pairable ?? false
    readonly property bool discoverable: Bluetooth.defaultAdapter?.discoverable ?? false
    readonly property string adapterName: Bluetooth.defaultAdapter?.name ?? ""
    readonly property string adapterId: Bluetooth.defaultAdapter?.adapterId ?? ""
    readonly property bool blocked: false  // Will be updated by rfkill check
    
    // Error state
    property string lastError: ""
    
    // Discovery timer
    property int discoveryDuration: 30000  // 30 seconds
    
    // Internal state to prevent multiple simultaneous stop operations
    property bool isStoppingDiscovery: false
    
    // ===== Device Lists =====
    
    readonly property var allDevices: Bluetooth.devices?.values ?? []
    // Filter devices: only show those with a proper name (not just MAC address)
    readonly property var visibleDevices: allDevices.filter(d => {
        const name = d.name || d.deviceName || "";
        // Check if name exists and is not just a MAC address pattern
        // MAC addresses look like: XX:XX:XX:XX:XX:XX or similar
        const isMacAddress = /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/.test(name);
        return name.length > 0 && !isMacAddress;
    })
    
    // Sorted device list - reactive property that updates when devices change
    readonly property var sortedDevices: {
        const devices = [...visibleDevices];
        return devices.sort((a, b) => {
            // Connected devices first
            if (a.connected && !b.connected) return -1;
            if (!a.connected && b.connected) return 1;
            
            // Then paired devices
            if (a.paired && !b.paired) return -1;
            if (!a.paired && b.paired) return 1;
            
            // Then sort by name
            return (a.name || a.deviceName || a.address).localeCompare(b.name || b.deviceName || b.address);
        });
    }
    
    readonly property var connectedDevices: visibleDevices.filter(d => d.connected)
    readonly property var pairedDevices: visibleDevices.filter(d => d.paired)
    
    // ===== Connection State =====
    
    readonly property bool hasConnectedDevices: connectedDevices.length > 0
    readonly property int connectedDeviceCount: connectedDevices.length
    readonly property var firstConnectedDevice: connectedDevices.length > 0 ? connectedDevices[0] : null
    readonly property string firstConnectedDeviceName: firstConnectedDevice?.name ?? ""
    
    // ===== Icon State =====
    
    readonly property string bluetoothIcon: {
        if (!enabled) return Fonts.iconBluetoothOff;
        if (hasConnectedDevices) return Fonts.iconBluetoothConnect;
        return Fonts.iconBluetooth;
    }
    
    // ===== Control Functions =====
    
    /**
     * Enable or disable Bluetooth adapter
     */
    function enableBluetooth(enabled = true): void {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.enabled = enabled;
        }
    }
    
    /**
     * Toggle Bluetooth on/off
     */
    function toggleBluetooth(): void {
        enableBluetooth(!root.enabled);
    }
    
    /**
     * Start scanning for nearby devices
     */
    function startDiscovery(): void {
        if (Bluetooth.defaultAdapter && root.enabled) {
            Bluetooth.defaultAdapter.discovering = true;
            // Start the timer to auto-stop discovery
            discoveryTimer.restart();
        }
    }
    
    /**
     * Stop scanning for devices and make adapter not discoverable
     */
    function stopDiscovery(): void {
        // Prevent multiple simultaneous stop operations
        if (root.isStoppingDiscovery) {
            console.log("Discovery stop already in progress, skipping...");
            return;
        }
        
        if (Bluetooth.defaultAdapter) {
            root.isStoppingDiscovery = true;
            
            try {
                // Only stop if actually discovering
                if (Bluetooth.defaultAdapter.discovering) {
                    Bluetooth.defaultAdapter.discovering = false;
                }
                
                // Make adapter not discoverable when closing panel
                if (Bluetooth.defaultAdapter.discoverable) {
                    Bluetooth.defaultAdapter.discoverable = false;
                }
            } catch (error) {
                // Silently ignore common errors during cleanup
                const errorStr = error.toString();
                if (!errorStr.includes("No discovery started") && 
                    !errorStr.includes("Operation already in progress")) {
                    console.error("Failed to stop discovery:", error);
                }
            } finally {
                // Always stop the timer and reset the flag
                discoveryTimer.stop();
                // Reset flag after a short delay to prevent rapid repeated calls
                Qt.callLater(() => {
                    root.isStoppingDiscovery = false;
                });
            }
        }
    }
    
    /**
     * Toggle device discovery
     */
    function toggleDiscovery(): void {
        if (root.discovering) {
            stopDiscovery();
        } else {
            startDiscovery();
        }
    }
    
    /**
     * Make adapter discoverable by other devices
     */
    function setDiscoverable(discoverable = true): void {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.discoverable = discoverable;
        }
    }
    
    /**
     * Set adapter pairable state
     */
    function setPairable(pairable = true): void {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.pairable = pairable;
        }
    }
    
    // ===== Device Functions =====
    
    /**
     * Connect to a Bluetooth device
     * Handles pairing if device is not yet paired
     */
    function connectDevice(device): void {
        if (!device || device.connected) return;
        
        // If device is not paired, pair it first
        if (!device.paired && !device.pairing) {
            console.log("Device not paired, initiating pairing for:", device.name || device.address);
            
            // Make adapter pairable
            if (Bluetooth.defaultAdapter) {
                Bluetooth.defaultAdapter.pairable = true;
                Bluetooth.defaultAdapter.discoverable = true;
            }
            
            // Trust device first for better pairing stability
            device.trusted = true;
            
            // Initiate pairing
            device.pair();
            
            // Note: Connection will happen automatically after pairing succeeds
            // via the onPairedChanged handler below
            return;
        }
        
        // Device is already paired, just connect
        if (device.paired && !device.connected) {
            console.log("Connecting to paired device:", device.name || device.address);
            if (!device.trusted) device.trusted = true;
            device.connect();
        }
    }
    
    /**
     * Disconnect from a Bluetooth device
     */
    function disconnectDevice(device): void {
        if (!device || !device.connected) return;
        device.disconnect();
    }
    
    /**
     * Forget (unpair) a device
     */
    function forgetDevice(device): void {
        if (!device) return;
        device.forget();
    }
    
    // ===== Background Processes =====
    
    // Start bluetoothctl agent to handle pairing
    Process {
        id: btAgent
        running: true
        command: ["bluetoothctl", "agent", "on"]
    }
    
    // ===== Timers =====
    
    // Auto-stop discovery after timeout
    Timer {
        id: discoveryTimer
        interval: root.discoveryDuration
        running: false
        repeat: false
        onTriggered: root.stopDiscovery()
    }
    
    // Stop discovery when Bluetooth is disabled
    onEnabledChanged: {
        if (!enabled) stopDiscovery();
    }
    
    // ===== Auto-trust and Auto-connect =====
    
    // Monitor device list changes to auto-trust newly paired devices
    Connections {
        target: Bluetooth.devices
        function onValuesChanged() {
            if (Bluetooth.devices) {
                [...Bluetooth.devices.values].forEach(device => {
                    // Auto-trust newly paired devices
                    if (device.paired && !device.trusted) {
                        console.log("Auto-trusting newly paired device:", device.name || device.address);
                        device.trusted = true;
                        
                        // Auto-connect after trusting (with small delay)
                        Qt.callLater(() => {
                            if (!device.connected) {
                                console.log("Auto-connecting trusted device:", device.name || device.address);
                                device.connect();
                            }
                        });
                    }
                });
            }
        }
    }
}
