pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.settings
import qs.components.animations

MouseArea {
    id: root

    // Orientation: "horizontal" (2x1) or "vertical" (1x2)
    required property string orientation
    
    // Quick action button properties
    required property string icon
    required property bool isActive
    property color disabledText: Colors.text
    property color disabledBackground: "transparent"
    property color disabledBorder: Colors.text
    
    // Label properties
    required property string label
    required property string sublabel
    
    // Expand menu properties
    property Component expandedContent: null  // Component to show when expanded
    property real expandedHeight: 600  // Desired height when expanded (default 600)
    
    // Meter/progress bar properties
    property bool showMeter: false  // Enable meter display
    property real meterLevel: 0.0  // Level from 0.0 to 1.0
    property color meterColor: root.accentColor  // Color of the meter fill
    
    // Signals
    signal quickActionClicked()
    signal expandClicked()
    
    // Accent color for active state
    property color accentColor: Config.controlCenterAccent
    property color inactiveColor: Colors.darken_20
    property color textColor: Colors.text
    property color subtextColor: Colors.textSubdued
    
    // Bubble is expanded or not
    property bool expanded: false
    
    // MouseArea configuration
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.expandClicked()
    
    // Visual background
    Rectangle {
        id: background
        anchors.fill: parent
        color: root.expanded ? "transparent" : root.inactiveColor
        radius: root.orientation === "horizontal" ? height / 4 : width / 4
        scale: parent.containsMouse ? 1.03 : 1

        AnimatedScale on scale{}
        
        // Meter fill (clipped to show level with rounded corners)
        ClippingRectangle {
            id: meterContainer
            anchors.fill: parent
            visible: root.showMeter && !root.expanded
            radius: background.radius
            color: "transparent"
            
            property bool animationsReady: false
            property real lastMeterLevel: root.meterLevel
            
            // Only enable animations after meterLevel actually changes
            Connections {
                target: root
                function onMeterLevelChanged() {
                    if (meterContainer.visible && meterContainer.lastMeterLevel !== root.meterLevel) {
                        meterContainer.animationsReady = true;
                        meterContainer.lastMeterLevel = root.meterLevel;
                    }
                }
            }
            
            // Disable animations when visibility changes (expand/collapse)
            onVisibleChanged: {
                if (visible) {
                    animationsReady = false;
                    lastMeterLevel = root.meterLevel;
                }
            }
            
            Rectangle {
                id: meterFill
                color: root.isActive ? root.meterColor : Qt.alpha(root.meterColor, 0.3)
                
                // Position and size based on orientation
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    right: root.orientation === "vertical" ? parent.right : undefined
                    top: root.orientation === "horizontal" ? parent.top : undefined
                }
                
                // Width for horizontal, height for vertical
                width: root.orientation === "horizontal" ? parent.width * root.meterLevel : parent.width
                height: root.orientation === "vertical" ? parent.height * root.meterLevel : parent.height
                
                AnimatedWidth on width {
                    enabled: meterContainer.animationsReady
                }
                
                AnimatedHeight on height {
                    enabled: meterContainer.animationsReady
                }
                
                AnimatedColor on color {}
            }
        }
    }
    
    // Main layout
    Item {
        id: bubbleContent
        anchors.fill: parent
        anchors.leftMargin: root.orientation === "horizontal" ? 16 : undefined
        anchors.rightMargin: root.orientation === "horizontal" ? 16 : undefined
        anchors.bottomMargin: root.orientation === "vertical" ? 16 : undefined
        anchors.topMargin: root.orientation === "vertical" ? 16 : undefined
        visible: !root.expanded
        
        // Quick action button (circular, positioned left/bottom depending on orientation)
        Rectangle {
            id: quickActionButton
            
            // Size: 60% of bubble width/height
            width: root.orientation === "horizontal" ? parent.height * 0.6 : parent.width * 0.6
            height: width
            radius: width
                        
            // Position: left for horizontal, bottom for vertical
            anchors {
                left: root.orientation === "horizontal" ? parent.left : undefined
                bottom: root.orientation === "vertical" ? parent.bottom : undefined
                horizontalCenter: root.orientation === "vertical" ? parent.horizontalCenter : undefined
                verticalCenter: root.orientation === "horizontal" ? parent.verticalCenter : undefined
            }
            
            color: root.isActive ? root.accentColor : root.disabledBackground
            border.width: root.isActive ? 0 : 1
            border.color: root.disabledBorder
            
            // Animations
            AnimatedColor on color {}
            AnimatedColor on border.color {}
            
            // Scale on hover
            scale: quickActionMouse.containsMouse ? 1.05 : 1.0
            AnimatedScale on scale {}
            
            // Icon
            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.isActive ? Colors.textSecondary : root.disabledText
                font.pixelSize: parent.width * 0.5
                font.family: Fonts.iconFont
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                
                AnimatedColor on color {}
            }
            
            // Mouse area for quick action
            MouseArea {
                id: quickActionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.quickActionClicked()
            }
        }
        
        // Label area (transparent, expands on click)
        Item {
            id: labelArea
            anchors {
                fill: parent
                // Don't overlap with quick action button
                leftMargin: root.orientation === "horizontal" ? quickActionButton.width + 12 : 0
                bottomMargin: root.orientation === "vertical" ? quickActionButton.height + 12 : 0
            }
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                width: parent.width
                
                Text {
                    Layout.fillWidth: true
                    text: root.label
                    color: root.textColor
                    font.pixelSize: Fonts.h6
                    font.bold: true
                    horizontalAlignment: root.orientation === "horizontal" ? Text.AlignLeft : Text.AlignHCenter
                    elide: Text.ElideRight
                    
                    AnimatedColor on color {}
                }
                
                Text {
                    Layout.fillWidth: true
                    text: root.sublabel
                    color: root.subtextColor
                    font.pixelSize: Fonts.p
                    horizontalAlignment: root.orientation === "horizontal" ? Text.AlignLeft : Text.AlignHCenter
                    elide: Text.ElideRight
                    
                    AnimatedColor on color {}
                }
            }
        }
    }
}
