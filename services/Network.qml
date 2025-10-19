pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.settings
import qs.services.network

/**
* Network service using nmcli to manage WiFi and Ethernet connections.
* Based on implementation from caelestia-dots/shell (GPLv3)
*/
Singleton {
    id: root

    // Connection type states
    property bool wifi: true
    property bool ethernet: false

    // WiFi states
    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property WifiAccessPoint wifiConnectTarget

    // WiFi networks list (mutable so we can add/remove networks)
    property var wifiNetworks: []

    readonly property WifiAccessPoint activeNetwork: {
        if (!wifiNetworks || wifiNetworks.length === 0)
            return null;
        return wifiNetworks.find(n => n.active) ?? null;
    }

    // Network info
    property string networkName: ""
    property int networkStrength: 0

    // Icon for current network state (uses Fonts icons)
    readonly property string wifiIcon: wifiEnabled ? Fonts.iconWifi : Fonts.iconWifiOff

    // ===== Control Functions =====

    /**
    * Enable or disable WiFi radio
    */
    function enableWifi(enabled = true): void {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    /**
    * Toggle WiFi on/off
    */
    function toggleWifi(): void {
        enableWifi(!wifiEnabled);
    }

    /**
    * Rescan for available WiFi networks
    */
    function rescanWifi(): void {
        wifiScanning = true;
        rescanProcess.running = true;
    }

    /**
    * Connect to a WiFi network
    */
    function connectToWifiNetwork(accessPoint: WifiAccessPoint): void {
        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;
        // Use `nmcli dev wifi connect` as it creates a connection profile automatically
        connectProc.exec(["nmcli", "dev", "wifi", "connect", accessPoint.ssid]);
    }

    /**
    * Disconnect from current WiFi network
    */
    function disconnectWifiNetwork(): void {
        if (activeNetwork) {
            disconnectProc.exec(["nmcli", "connection", "down", activeNetwork.ssid]);
        }
    }

    /**
    * Open public WiFi portal (for captive portal login)
    */
    function openPublicWifiPortal(): void {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]);
    }

    /**
    * Change password for a WiFi network
    */
    function changePassword(network: WifiAccessPoint, password: string): void {
        network.askingPassword = false;
        root.wifiConnectTarget = network;

        // Delete any existing connection profile first to avoid incomplete settings,
        // then connect with password using printf to pipe the password to nmcli --ask
        changePasswordProc.exec({
            "environment": {
                "PASSWORD": password,
                "SSID": network.ssid
            },
            "command": ["bash", "-c", `nmcli connection delete "$SSID" 2>/dev/null; printf '%s\\n' "$PASSWORD" | nmcli --ask dev wifi connect "$SSID"`]
        });
    }

    // ===== Internal Processes =====

    Process {
        id: enableWifiProc
        onExited: root.update()
    }

    Process {
        id: connectProc
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: SplitParser {
            onRead: line => {
                console.log("WiFi connect:", line);
                getNetworks.running = true;
            }
        }
        stderr: SplitParser {
            onRead: line => {
                console.error("WiFi connect error:", line);
                if (line.includes("Secrets were required") && root.wifiConnectTarget) {
                    root.wifiConnectTarget.askingPassword = true;
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (root.wifiConnectTarget) {
                root.wifiConnectTarget.askingPassword = (exitCode !== 0);
            }
            if (exitCode === 0) {
                root.update();
            }
            root.wifiConnectTarget = null;
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: () => {
                getNetworks.running = true;
                root.update();
            }
        }
    }

    Process {
        id: changePasswordProc
        stdout: SplitParser {
            onRead: line => {
                console.log("WiFi password connect:", line);
                getNetworks.running = true;
            }
        }
        stderr: SplitParser {
            onRead: line => {
                console.error("WiFi password connect error:", line);
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.update();
            } else if (root.wifiConnectTarget) {
                root.wifiConnectTarget.askingPassword = true;
            }
            root.wifiConnectTarget = null;
        }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: () => {
                getNetworks.running = true;
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.wifiScanning = false;
        }
    }

    // ===== Status Monitoring =====

    /**
    * Update all network status information
    */
    function update(): void {
        updateConnectionType.startCheck();
        wifiStatusProcess.running = true;
        updateNetworkName.running = true;
        updateNetworkStrength.running = true;
        getNetworks.running = true;
    }

    // Monitor network changes
    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    // Check connection type (WiFi vs Ethernet)
    Process {
        id: updateConnectionType
        property string buffer
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE,DEVICE c show --active"]
        running: true

        function startCheck(): void {
            buffer = "";
            updateConnectionType.running = true;
        }

        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }

        onExited: (exitCode, exitStatus) => {
            const lines = updateConnectionType.buffer.trim().split('\n');
            let hasEthernet = false;
            let hasWifi = false;

            lines.forEach(line => {
                if (line.includes("ethernet"))
                    hasEthernet = true;
                else if (line.includes("wireless"))
                    hasWifi = true;
            });

            root.ethernet = hasEthernet;
            root.wifi = hasWifi;
        }
    }

    // Get active network name
    Process {
        id: updateNetworkName
        command: ["sh", "-c", "nmcli -t -f NAME c show --active | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.networkName = data.trim();
            }
        }
    }

    // Get WiFi signal strength
    Process {
        id: updateNetworkStrength
        running: true
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\\*/{if (NR!=1) {print $2}}'"]
        stdout: SplitParser {
            onRead: data => {
                root.networkStrength = parseInt(data) || 0;
            }
        }
    }

    // Check if WiFi is enabled
    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        Component.onCompleted: running = true
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    // Get list of available WiFi networks
    Process {
        id: getNetworks
        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3],
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] || ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                    }
                }

                // Sort networks: active first, then by signal strength
                const wifiNetworks = Array.from(networkMap.values()).sort((a, b) => {
                    // Active networks first
                    if (a.active && !b.active)
                        return -1;
                    if (!a.active && b.active)
                        return 1;
                    // Then by signal strength (descending)
                    return b.strength - a.strength;
                });

                const rNetworks = root.wifiNetworks;
                // Remove networks that no longer exist
                const destroyed = rNetworks.filter(rn => !wifiNetworks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));

                for (const network of destroyed) {
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());
                }

                // Clear and rebuild the list to maintain proper order
                const newNetworkList = [];

                // Update or create network objects in sorted order
                for (const network of wifiNetworks) {
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);

                    if (match) {
                        match.lastIpcObject = network;
                        newNetworkList.push(match);
                    } else {
                        const newAp = apComp.createObject(root, {
                            lastIpcObject: network
                        });
                        newNetworkList.push(newAp);
                    }
                }

                // Replace the entire list to trigger proper refresh
                root.wifiNetworks = newNetworkList;
            }
        }
    }

    Component {
        id: apComp
        WifiAccessPoint {}
    }

    // Initialize on component creation
    Component.onCompleted: {
        update();
    }
}
