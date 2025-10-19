pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.settings
import qs.services
import qs.components
import qs.components.animations

Rectangle {
    id: root
    
    required property var device
    
    signal connectClicked()
    signal disconnectClicked()
    signal forgetClicked()
    
    height: mainContent.implicitHeight + 24  // 12px margins top+bottom
    color: (mouseArea.containsMouse && !root.device.connected) ? Colors.brighten_10 : "transparent"
    radius: 8
    
    AnimatedColor on color {}
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        z: 0
        enabled: !root.device.connected && !root.device.pairing
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        
        onClicked: {
            if (!root.device.connected) {
                root.connectClicked();
            }
        }
    }
    
    // Subtle separator line at bottom
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 1
        color: Colors.brighten_3
        z: 1
    }
    
    ColumnLayout {
        id: mainContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8
        z: 10  // Ensure content and buttons are above the MouseArea
        
        // Main device info row
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Connected checkmark
            Text {
                visible: root.device.connected
                text: Fonts.iconTrue
                color: Colors.green
                font.pixelSize: 18
                font.family: Fonts.iconFont
            }

            // Device type icon
            Text {
                text: root.getDeviceIconText()
                color: Colors.text
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 18
                font.family: Fonts.iconFont
            }
            
            // Device name
            Text {
                Layout.fillWidth: true
                text: {
                    const name = root.device.name || root.device.deviceName || "";
                    const macPattern = /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/;
                    const isMacAddress = name.match(macPattern) !== null;
                    return (name.length > 0 && !isMacAddress) ? name : "Unknown Device";
                }
                horizontalAlignment: Text.AlignLeft
                color: Colors.text
                font.pixelSize: Fonts.h5
                elide: Text.ElideRight
            }
            
            // Battery indicator
            RowLayout {
                spacing: 4
                visible: root.device.batteryAvailable
                
                Text {
                    text: Fonts.iconBattery
                    color: Colors.textSubdued
                    font.pixelSize: 14
                    font.family: Fonts.iconFont
                }
                
                Text {
                    text: Math.round(root.device.battery * 100) + "%"
                    color: Colors.textSubdued
                    font.pixelSize: Fonts.p
                }
            }
            
            // Pairing spinner
            Text {
                id: pairingSpinner
                visible: root.device.pairing
                text: Fonts.iconSpinner
                color: Colors.text
                font.pixelSize: 16
                font.family: Fonts.iconFont
                
                RotationAnimator on rotation {
                    running: pairingSpinner.visible
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }
            
            // Status text for non-connected devices
            Text {
                visible: !root.device.connected && !root.device.pairing
                text: root.device.paired ? "Paired" : "Available"
                color: root.device.paired ? Config.controlCenterAccent : Colors.textSubdued
                font.pixelSize: Fonts.p
            }

            // Disconnect Button
            ActionButton {
                visible: root.device.connected
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 12
                icon: Fonts.iconFalse
                textColor: Colors.text
                backgroundColor: Colors.red
                borderColor: Colors.red
                onClicked: root.disconnectClicked()
            }
            
            // Forget/Unpair Button (shown for paired but not connected devices)
            ActionButton {
                visible: root.device.paired && !root.device.connected
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 12
                icon: Fonts.iconFalse
                textColor: Colors.text
                backgroundColor: Colors.red
                borderColor: Colors.red
                onClicked: root.forgetClicked()
            }
        }
    }
    
    function getDeviceIconText(): string {
        const icon = root.device.icon || "";
        
        if (icon.includes("audio") || icon.includes("headset") || icon.includes("headphone")) {
            return Fonts.iconHeadset;
        } else if (icon.includes("phone") || icon.includes("smartphone")) {
            return Fonts.iconPhone;
        } else if (icon.includes("computer") || icon.includes("laptop")) {
            return Fonts.iconComputer;
        } else if (icon.includes("input") || icon.includes("keyboard")) {
            return Fonts.iconKeyboard;
        } else if (icon.includes("mouse")) {
            return Fonts.iconMouse;
        } else if (icon.includes("speaker")) {
            return Fonts.iconSpeaker;
        } else {
            return Fonts.iconBluetooth;
        }
    }
}
