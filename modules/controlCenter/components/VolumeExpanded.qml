pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.settings
import qs.services
import qs.components
import qs.components.animations
import qs.modules.controlCenter.components

/**
 * VolumeExpanded: Comprehensive audio control panel for the control center
 * 
 * Provides:
 * - Master volume control with mute toggle and visual feedback
 * - Application volume mixer (Pipewire audio source control)
 * - Output device selection and management
 * - Input device selection and management
 * 
 * Tab-based navigation with smooth animations and real-time audio sync.
 */
ExpandedBubble {
    id: root
    
    title: "Volume"
    showHeader: true
    
    /// Active tab index: 0=Mixer, 1=Output, 2=Input
    property int currentTab: 0
    
    /// Tracks Pipewire sink/source changes for real-time device updates
    PwObjectTracker {
        objects: [Audio.sink, Audio.source]
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 16
        
        // Master Volume Control
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                /// Mute/unmute toggle with dynamic icon and color feedback
                ActionButton {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    
                    icon: Audio.volumeIcon
                    iconSize: 0.5
                    backgroundColor: Audio.muted ? Colors.red : Config.controlCenterAccent
                    borderColor: Audio.muted ? Colors.red : Config.controlCenterAccent
                    textColor: Colors.textSecondary
                    
                    onClicked: Audio.toggleMute()
                }
                
                // Master volume label
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: "Master Volume"
                    color: Colors.text
                    font.pixelSize: Fonts.h5
                    font.bold: true
                }
                
                // Current volume percentage display
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: Audio.volumePercent + "%"
                    color: Colors.textSubdued
                    font.pixelSize: Fonts.h6
                }
            }
            
            /// Interactive volume slider with meter fill and smooth animations
            ClippingRectangle {
                id: masterVolumeBar
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                
                radius: 12
                color: Colors.brighten_5
                
                property bool userInteracting: false
                
                // Meter fill
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.max(0, Math.min(1, Audio.volume))
                    color: Audio.muted ? Qt.alpha(Config.controlCenterAccent, 0.3) : Config.controlCenterAccent
                    
                    AnimatedWidth on width {
                        enabled: !masterVolumeBar.userInteracting
                    }
                    
                    AnimatedColor on color {}
                }
                
                MouseArea {
                    anchors.fill: parent
                    enabled: !Audio.muted
                    hoverEnabled: !Audio.muted
                    cursorShape: Audio.muted ? Qt.ArrowCursor : Qt.PointingHandCursor
                    
                    property real lastSetVolume: -1
                    
                    onPressed: (mouse) => {
                        masterVolumeBar.userInteracting = true;
                        lastSetVolume = -1;
                        updateVolume(mouse.x);
                    }
                    
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            updateVolume(mouse.x);
                        }
                    }
                    
                    onReleased: {
                        masterVolumeBar.userInteracting = false;
                        lastSetVolume = -1;
                    }
                    
                    /// Convert mouse position to volume (0-1), rounded to 1% increments to reduce rapid updates
                    function updateVolume(x: real): void {
                        const rawVolume = Math.max(0, Math.min(1, x / width));
                        const roundedVolume = Math.round(rawVolume * 100) / 100;
                        
                        if (roundedVolume !== lastSetVolume) {
                            lastSetVolume = roundedVolume;
                            Audio.setVolume(roundedVolume);
                        }
                    }
                }
            }
        }
        
        // Tab Navigation
        Tabs {
            id: tabs
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            currentTab: root.currentTab
            tabModel: ["Mixer", "Output", "Input"]
            activeColor: Config.controlCenterAccent
            
            onTabChanged: (index) => {
                root.currentTab = index;
            }
        }
        
        // Content Loader for different tabs
        Loader {
            id: contentLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            sourceComponent: {
                switch (root.currentTab) {
                    case 0:
                        return volumeMixerComponent;
                    case 1:
                        return outputDevicesComponent;
                    case 2:
                        return inputDevicesComponent;
                    default:
                        return volumeMixerComponent;
                }
            }
        }
    }
    
    // Volume Mixer Component (Apps)
    Component {
        id: volumeMixerComponent
        
        ColumnLayout {
            spacing: 8
            
            // Application Volume Mixer List
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Colors.brighten_3
                radius: 8
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 0
                    
                    // Active application audio sources
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 200
                        visible: Audio.appNodes.length > 0
                        clip: true
                        
                        ListView {
                            id: appList
                            width: parent.width
                            model: Audio.appNodes
                            spacing: 24
                            interactive: true
                            boundsBehavior: Flickable.StopAtBounds
                            
                            delegate: VolumeMixerEntry {
                                required property var modelData
                                required property int index
                                
                                width: appList.width
                                node: modelData
                            }
                        }
                    }
                    
                    // Empty state when no applications are playing audio
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true 
                        Layout.alignment : Qt.AlignVCenter
                        visible: Audio.appNodes.length === 0
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Fonts.iconVolumeMute
                                font.family: Fonts.iconFont
                                font.pixelSize: 48
                                color: Colors.textSubdued
                                opacity: 0.5
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No active audio sources"
                                color: Colors.textSubdued
                                font.pixelSize: Fonts.p
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Output Devices Component
    Component {
        id: outputDevicesComponent
        
        ColumnLayout {
            spacing: 8
            
            // Output Devices List
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Colors.brighten_3
                radius: 8
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 0
                    
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        
                        ListView {
                            id: outputDevicesList
                            width: parent.width
                            model: Audio.outputDevices
                            spacing: 8
                            interactive: true
                            boundsBehavior: Flickable.StopAtBounds
                            
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                
                                id: outputDeviceItem
                                
                                width: outputDevicesList.width
                                height: 60
                                
                                radius: 8
                                color: deviceMouseArea.containsMouse ? Colors.brighten_10 : "transparent"
                                border.width: outputDeviceItem.isSelected ? 2 : 0
                                border.color: Config.controlCenterAccent
                                
                                /// Determines if this device is currently the active selection
                                property bool isSelected: {
                                    return Audio.sink?.id === outputDeviceItem.modelData.id;
                                }
                                
                                AnimatedColor on color {}
                                AnimatedColor on border.color {}
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12
                                    
                                    /// Device type icon
                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: Fonts.iconSpeaker
                                        font.family: Fonts.iconFont
                                        font.pixelSize: 28
                                        color: outputDeviceItem.isSelected ? Config.controlCenterAccent : Colors.text
                                        
                                        AnimatedColor on color {}
                                    }
                                    
                                    /// Device name/description
                                    Text {
                                        Layout.fillWidth: true
                                        text: outputDeviceItem.modelData.description || outputDeviceItem.modelData.name || "Unknown Device"
                                        color: Colors.text
                                        font.pixelSize: Fonts.p
                                        font.bold: outputDeviceItem.isSelected
                                        elide: Text.ElideRight
                                        
                                        AnimatedColor on color {}
                                    }
                                    
                                    /// Selection indicator dot
                                    Rectangle {
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        radius: 10
                                        color: "transparent"
                                        border.width: 2
                                        border.color: outputDeviceItem.isSelected ? Config.controlCenterAccent : Colors.textSubdued
                                        
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 10
                                            height: 10
                                            radius: 5
                                            color: Config.controlCenterAccent
                                            visible: outputDeviceItem.isSelected
                                        }
                                        
                                        AnimatedColor on border.color {}
                                    }
                                }
                                
                                MouseArea {
                                    id: deviceMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    onClicked: Audio.setDefaultSink(outputDeviceItem.modelData)
                                }
                            }
                        }
                    }
                    
                    // Empty state when no output devices are available
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: Audio.outputDevices.length === 0
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Fonts.iconSpeaker
                                font.family: Fonts.iconFont
                                font.pixelSize: 48
                                color: Colors.textSubdued
                                opacity: 0.5
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No output devices available"
                                color: Colors.textSubdued
                                font.pixelSize: Fonts.p
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Input Devices Component
    Component {
        id: inputDevicesComponent
        
        ColumnLayout {
            spacing: 8
            
            // Input Devices List
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Colors.brighten_3
                radius: 8
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 0
                    
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        
                        ListView {
                            id: inputDevicesList
                            width: parent.width
                            model: Audio.inputDevices
                            spacing: 8
                            interactive: true
                            boundsBehavior: Flickable.StopAtBounds
                            
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                
                                id: inputDeviceItem
                                
                                width: inputDevicesList.width
                                height: 60
                                
                                radius: 8
                                color: deviceMouseArea.containsMouse ? Colors.brighten_10 : "transparent"
                                border.width: inputDeviceItem.isSelected ? 2 : 0
                                border.color: Config.controlCenterAccent
                                
                                /// Determines if this device is currently the active selection
                                property bool isSelected: {
                                    return Audio.source?.id === inputDeviceItem.modelData.id;
                                }
                                
                                AnimatedColor on color {}
                                AnimatedColor on border.color {}
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12
                                    
                                    /// Device type icon
                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: Fonts.iconHeadset
                                        font.family: Fonts.iconFont
                                        font.pixelSize: 28
                                        color: inputDeviceItem.isSelected ? Config.controlCenterAccent : Colors.text
                                        
                                        AnimatedColor on color {}
                                    }
                                    
                                    /// Device name/description
                                    Text {
                                        Layout.fillWidth: true
                                        text: inputDeviceItem.modelData.description || inputDeviceItem.modelData.name || "Unknown Device"
                                        color: Colors.text
                                        font.pixelSize: Fonts.p
                                        font.bold: inputDeviceItem.isSelected
                                        elide: Text.ElideRight
                                        
                                        AnimatedColor on color {}
                                    }
                                    
                                    /// Selection indicator dot
                                    Rectangle {
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20
                                        radius: 10
                                        color: "transparent"
                                        border.width: 2
                                        border.color: inputDeviceItem.isSelected ? Config.controlCenterAccent : Colors.textSubdued
                                        
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 10
                                            height: 10
                                            radius: 5
                                            color: Config.controlCenterAccent
                                            visible: inputDeviceItem.isSelected
                                        }
                                        
                                        AnimatedColor on border.color {}
                                    }
                                }
                                
                                MouseArea {
                                    id: deviceMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    onClicked: Audio.setDefaultSource(inputDeviceItem.modelData)
                                }
                            }
                        }
                    }
                    
                    // Empty state when no input devices are available
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: Audio.inputDevices.length === 0
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Fonts.iconHeadset
                                font.family: Fonts.iconFont
                                font.pixelSize: 48
                                color: Colors.textSubdued
                                opacity: 0.5
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No input devices available"
                                color: Colors.textSubdued
                                font.pixelSize: Fonts.p
                            }
                        }
                    }
                }
            }
        }
    }
}
