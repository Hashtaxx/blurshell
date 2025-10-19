pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.settings
import qs.services
import qs.components
import qs.components.animations

/**
 * WifiNetworkItem: Individual WiFi network list item for network selection
 *
 * Displays network information with connection status, signal strength, and security indicators.
 * Supports secure network authentication via inline password input with visual feedback during connection.
 * Provides disconnect functionality for active connections and hover state visual feedback.
 */
Rectangle {
    id: root
    
    required property var network
    
    signal clicked()
    
    // Component height: content + top/bottom margins (12px each)
    height: mainContent.implicitHeight + 24
    color: (mouseArea.containsMouse && !root.network.active) ? Colors.brighten_10 : "transparent"
    radius: 8
    
    AnimatedColor on color {}
    
    // Visual separator between network items
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 1
        color: Colors.brighten_3
    }
    
    ColumnLayout {
        id: mainContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8
        
        // Main network information row displaying status and details
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Connected status indicator
            Text {
                visible: root.network.active
                text: Fonts.iconTrue
                color: Colors.green
                font.pixelSize: 18
                font.family: Fonts.iconFont
            }

            // Signal strength icon based on network quality
            Text {
                text: root.network.strengthIcon
                color: Colors.text
                Layout.preferredWidth: 16
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 18
                font.family: Fonts.iconFont
            }

            // Signal strength percentage display
            Text {
                text: root.network.strength + "%"
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignLeft
                color: Colors.textSubdued
                font.pixelSize: Fonts.p
                visible: !root.network.askingPassword
            }
            
            // Network SSID (name) with text truncation for long names
            Text {
                Layout.fillWidth: true
                text: root.network.ssid
                horizontalAlignment: Text.AlignLeft
                color: Colors.text
                font.pixelSize: Fonts.h5
                elide: Text.ElideRight
            }
            
            // Security badge indicator for password-protected networks
            Text {
                visible: root.network.isSecure
                text: Fonts.iconLock
                color: Colors.textSubdued
                font.pixelSize: 14
                font.family: Fonts.iconFont
            }
            
            // Connection progress spinner with continuous rotation animation
            Text {
                id: connectingSpinner
                visible: Network.wifiConnecting && Network.wifiConnectTarget && Network.wifiConnectTarget === root.network
                text: Fonts.iconSpinner
                color: Colors.text
                font.pixelSize: 16
                font.family: Fonts.iconFont
                
                RotationAnimator on rotation {
                    running: connectingSpinner.visible
                    from: 0
                    to: 360
                    duration: AnimationConfig.verySlow
                    loops: Animation.Infinite
                }
            }

            // Disconnect button for active connections
            ActionButton {
                visible: root.network.active
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 12
                icon: Fonts.iconFalse
                textColor: Colors.text
                backgroundColor: Colors.red
                borderColor: Colors.red
                onClicked: Network.disconnectWifiNetwork()
            }
        }
        
        // Password input field for secure network authentication
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 8
            visible: root.network.askingPassword
            
            // Cancel password entry and revert to network selection
            ActionButton {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                icon: Fonts.iconFalse
                textColor: Colors.red
                backgroundColor: "transparent"
                borderColor: Colors.red
                iconSize: 0.5
                onClicked: {
                    root.network.askingPassword = false
                    passwordField.text = ""
                }
            }
            
            // Secure password input with focus-based border highlight
            TextField {
                id: passwordField
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                placeholderText: "Password"
                echoMode: TextInput.Password
                color: Colors.text
                font.pixelSize: Fonts.p
                verticalAlignment: TextInput.AlignVCenter
                leftPadding: 6
                rightPadding: 6
                topPadding: 6
                bottomPadding: 6
                
                background: Rectangle {
                    color: Colors.darken_20
                    radius: 4
                    border.width: passwordField.activeFocus ? 2 : 1
                    border.color: passwordField.activeFocus ? Colors.lavender : Colors.brighten_20
                    
                    AnimatedColor on border.color {}
                }
                
                onAccepted: root.attemptNetworkConnection()
            }
            
            // Submit password and connect to network
            ActionButton {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                icon: Fonts.iconTrue
                textColor: Colors.green
                backgroundColor: "transparent"
                borderColor: Colors.green
                iconSize: 0.5
                onClicked: root.attemptNetworkConnection()
            }
        }
    }
    
    // Mouse area for clicking network
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !root.network.askingPassword && !root.network.active
        onClicked: root.clicked()
    }
    
    // Helper function to validate and submit password for network connection
    function attemptNetworkConnection() {
        if (passwordField.text.length > 0) {
            Network.changePassword(root.network, passwordField.text)
        }
    }
}
