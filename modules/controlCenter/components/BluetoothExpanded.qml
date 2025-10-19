pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.settings
import qs.services
import qs.components

ExpandedBubble {
    id: root
    
    title: "Bluetooth"
    showHeader: true
    property color background: "transparent"
    
    // Stop discovery when becoming invisible (handles both collapse and close)
    onVisibleChanged: {
        if (!visible) {
            Bluetooth.stopDiscovery();
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        
        // Discoverable Status (when enabled and discoverable)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            visible: Bluetooth.enabled && Bluetooth.discoverable
            color: "transparent"
            radius: 8
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 12
                
                Text {
                    text: Fonts.iconEye
                    color: Colors.text
                    Layout.preferredWidth: 16
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 20
                    font.family: Fonts.iconFont
                }

                Text {
                    text: "Discoverable"
                    color: Colors.text
                    font.pixelSize: Fonts.h5
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "Visible " + Fonts.iconTrue
                    color: Colors.green
                    font.pixelSize: Fonts.h5
                }
            }
        }
        
        // Bluetooth Toggle
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: root.background
            radius: 8
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 12
                
                Text {
                    text: Bluetooth.bluetoothIcon
                    color: Colors.text
                    Layout.preferredWidth: 16
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 20
                    font.family: Fonts.iconFont
                }
                
                Text {
                    Layout.fillWidth: true
                    text: "Bluetooth"
                    color: Colors.text
                    font.pixelSize: Fonts.h5
                }
                
                Toggle {
                    checkedColor: Config.controlCenterAccent
                    checked: Bluetooth.enabled
                    
                    onToggled: (checked) => {
                        Bluetooth.enableBluetooth(checked);
                        if (checked) {
                            Bluetooth.startDiscovery();
                        }
                    }
                }
            }
        }

        // Bluetooth Devices List
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.brighten_3
            radius: 8
            visible: Bluetooth.enabled
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 0
                
                // Devices list
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 200
                    clip: true
                    
                    ListView {
                        id: devicesList
                        width: parent.width
                        model: Bluetooth.sortedDevices
                        spacing: 4
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
                        
                        delegate: BluetoothDeviceItem {
                            required property var modelData
                            required property int index
                            
                            width: devicesList.width
                            device: modelData
                            
                            onConnectClicked: {
                                // Use the service connect function which handles pairing + connection
                                Bluetooth.connectDevice(device);
                            }
                            
                            onDisconnectClicked: {
                                Bluetooth.disconnectDevice(device);
                            }
                            
                            onForgetClicked: {
                                Bluetooth.forgetDevice(device);
                            }
                        }
                        
                        // Scan status and button as footer
                        footer: Item {
                            width: devicesList.width
                            height: 48
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 12
                                
                                // Scanning indicator text
                                Text {
                                    visible: Bluetooth.discovering
                                    text: "Scanning for devices..."
                                    color: Colors.textSubdued
                                    font.pixelSize: Fonts.p
                                    
                                    // Subtle pulsing animation
                                    opacity: scanPulse.running ? 0.5 + (scanPulse.value * 0.5) : 1.0
                                    
                                    SequentialAnimation {
                                        id: scanPulse
                                        running: Bluetooth.discovering
                                        loops: Animation.Infinite
                                        
                                        property real value: 0
                                        
                                        NumberAnimation {
                                            target: scanPulse
                                            property: "value"
                                            from: 0
                                            to: 1
                                            duration: 1000
                                            easing.type: Easing.InOutQuad
                                        }
                                        NumberAnimation {
                                            target: scanPulse
                                            property: "value"
                                            from: 1
                                            to: 0
                                            duration: 1000
                                            easing.type: Easing.InOutQuad
                                        }
                                    }
                                }
                                
                                ReloadButton {
                                    isLoading: false  // Never spin, just show button
                                    onClicked: {
                                        if (Bluetooth.discovering) {
                                            Bluetooth.stopDiscovery();
                                        } else {
                                            Bluetooth.startDiscovery();
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Show message when no devices
                        ColumnLayout {
                            anchors.centerIn: parent
                            visible: devicesList.count === 0
                            spacing: 12
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Bluetooth.discovering ? "Scanning for devices..." : "No devices found"
                                color: Colors.textSubdued
                                font.pixelSize: Fonts.p
                                horizontalAlignment: Text.AlignHCenter
                            }
                            
                            ReloadButton {
                                Layout.alignment: Qt.AlignHCenter
                                visible: !Bluetooth.discovering
                                isLoading: false
                                onClicked: Bluetooth.startDiscovery()
                            }
                        }
                    }
                }
            }
        }
        
        // Bluetooth disabled message
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.brighten_3
            radius: 8
            visible: !Bluetooth.enabled
            
            Text {
                anchors.centerIn: parent
                text: "Bluetooth is disabled"
                color: Colors.textSubdued
                font.pixelSize: Fonts.h5
            }
        }
    }
}
