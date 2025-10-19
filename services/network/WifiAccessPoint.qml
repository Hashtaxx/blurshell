pragma ComponentBehavior: Bound
import QtQuick
import qs.settings

QtObject {
    id: root
    
    // Properties from nmcli output
    property bool active: false
    property int strength: 0
    property int frequency: 0
    property string ssid: ""
    property string bssid: ""
    property string security: ""
    
    // UI state
    property bool askingPassword: false
    
    // Internal - last IPC object from nmcli
    property var lastIpcObject: null
    
    // Computed properties
    readonly property bool isSecure: security.trim().length > 0
    readonly property string strengthIcon: Fonts.iconWifi  // Simple WiFi icon
    
    // Update properties when lastIpcObject changes
    onLastIpcObjectChanged: {
        if (lastIpcObject) {
            active = lastIpcObject.active ?? false
            strength = lastIpcObject.strength ?? 0
            frequency = lastIpcObject.frequency ?? 0
            ssid = lastIpcObject.ssid ?? ""
            bssid = lastIpcObject.bssid ?? ""
            security = lastIpcObject.security ?? ""
        }
    }
}
