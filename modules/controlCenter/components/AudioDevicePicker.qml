pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.settings
import qs.services
import qs.components.animations

Item {
    id: root
    
    property bool isInput: false
    property var selectedDevice: null
    
    signal deviceSelected(var device)
    signal cancelled()
    
    readonly property var availableDevices: isInput ? Audio.inputDevices : Audio.outputDevices
    
    // Semi-transparent overlay
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: Colors.bg
        opacity: 0.95
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.cancelled()
        }
    }
    
    // Dialog box
    Rectangle {
        id: dialog
        anchors.centerIn: parent
        width: Math.min(parent.width - 60, 500)
        height: Math.min(parent.height - 120, contentColumn.implicitHeight + 48)
        
        color: Colors.brighten_10
        radius: 12
        
        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16
            
            // Header
            Text {
                Layout.fillWidth: true
                text: root.isInput ? "Select Input Device" : "Select Output Device"
                color: Colors.text
                font.pixelSize: Fonts.h4
                font.bold: true
            }
            
            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colors.textSubdued
                opacity: 0.3
            }
            
            // Device list
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                contentHeight: deviceColumn.implicitHeight
                
                ColumnLayout {
                    id: deviceColumn
                    width: parent.width
                    spacing: 8
                    
                    Repeater {
                        model: root.availableDevices
                        
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            
                            id: deviceItem
                            
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            
                            radius: 8
                            color: deviceMouseArea.containsMouse ? Colors.brighten_10 : "transparent"
                            border.width: deviceItem.isSelected ? 2 : 0
                            border.color: Config.controlCenterAccent
                            
                            property bool isSelected: {
                                const currentDevice = root.isInput ? Audio.source : Audio.sink;
                                return currentDevice?.id === deviceItem.modelData.id;
                            }
                            
                            AnimatedColor on color {}
                            AnimatedColor on border.color {}
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12
                                
                                // Radio indicator
                                Rectangle {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    radius: 10
                                    color: "transparent"
                                    border.width: 2
                                    border.color: deviceItem.isSelected ? Config.controlCenterAccent : Colors.textSubdued
                                    
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: Config.controlCenterAccent
                                        visible: deviceItem.isSelected
                                    }
                                    
                                    AnimatedColor on border.color {}
                                }
                                
                                // Device name
                                Text {
                                    Layout.fillWidth: true
                                    text: deviceItem.modelData.description || deviceItem.modelData.name || "Unknown Device"
                                    color: Colors.text
                                    font.pixelSize: Fonts.p
                                    elide: Text.ElideRight
                                    
                                    AnimatedColor on color {}
                                }
                            }
                            
                            MouseArea {
                                id: deviceMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onClicked: {
                                    root.selectedDevice = deviceItem.modelData;
                                    root.deviceSelected(deviceItem.modelData);
                                }
                            }
                        }
                    }
                }
            }
            
            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colors.textSubdued
                opacity: 0.3
            }
            
            // Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing: 12
                
                // Cancel button
                Rectangle {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 36
                    radius: 8
                    color: cancelMouse.containsMouse ? Colors.brighten_10 : "transparent"
                    border.width: 1
                    border.color: Colors.textSubdued
                    
                    AnimatedColor on color {}
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Colors.text
                        font.pixelSize: Fonts.p
                    }
                    
                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancelled()
                    }
                }
            }
        }
    }
}
