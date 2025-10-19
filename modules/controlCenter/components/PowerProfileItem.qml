pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.UPower
import qs.settings
import qs.services
import qs.components.animations

Rectangle {
    id: root
    
    required property int profileType  // PowerProfile enum value
    required property bool isActive
    required property bool isAvailable
    
    signal clicked()
    
    // No fixed height - will be set by Layout.fillHeight in parent
    color: isActive ? Config.controlCenterAccent : (mouseArea.containsMouse && isAvailable ? Colors.brighten_10 : Colors.brighten_3)
    radius: 12
    opacity: isAvailable ? 1.0 : 0.5
    
    AnimatedColor on color {}
    
    // Profile information
    readonly property string profileName: {
        switch (profileType) {
            case PowerProfile.Performance: return "Performance";
            case PowerProfile.Balanced: return "Balanced";
            case PowerProfile.PowerSaver: return "Power Saver";
            default: return "Unknown";
        }
    }
    
    readonly property string profileIcon: {
        switch (profileType) {
            case PowerProfile.Performance: return Fonts.iconPowerFast;
            case PowerProfile.Balanced: return Fonts.iconPowerMedium;
            case PowerProfile.PowerSaver: return Fonts.iconPowerEco;
            default: return Fonts.iconPowerMedium;
        }
    }
    
    readonly property string profileDescription: {
        switch (profileType) {
            case PowerProfile.Performance: return "Maximum performance";
            case PowerProfile.Balanced: return "Balance performance and power";
            case PowerProfile.PowerSaver: return "Maximize battery life";
            default: return "";
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.isAvailable && !root.isActive
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        
        onClicked: {
            if (root.isAvailable && !root.isActive) {
                root.clicked();
            }
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // Profile icon
        Text {
            text: root.profileIcon
            color: root.isActive ? Colors.bg : Colors.text
            font.pixelSize: 28
            font.family: Fonts.iconFont
            
            AnimatedColor on color {}
        }
        
        // Profile name
        Text {
            Layout.fillWidth: true
            text: root.profileName
            color: root.isActive ? Colors.bg : Colors.text
            font.pixelSize: Fonts.h4
            font.weight: Font.Medium
            
            AnimatedColor on color {}
        }
    }
}
