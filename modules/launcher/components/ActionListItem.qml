pragma ComponentBehavior: Bound

import QtQuick
import qs.settings
import qs.modules.launcher
import qs.components.animations

/**
 * ActionListItem: Launcher action list item with selection state and icon support
 * 
 * A reusable list item component for launcher actions with visual selection feedback.
 * Displays a prefixed icon, action name, and custom content with smooth animations.
 * 
 * Properties:
 * - selected: Controls visual selection state and color animation
 * - actionName: The display name of the action
 * - content: Custom children for flexible content layout
 */
Item {
    id: root
    
    property bool selected: false
    property string actionName: ""
    property alias content: actionContent.children
    
    width: parent.width
    height: LauncherConfig.actionItemHeight
    
    // Background with dynamic color based on selection state
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.selected ? Colors.brighten_10 : "transparent"
        
        AnimatedColor on color {
            animationDuration: AnimationConfig.fast
        }
    }
    
    Row {
        anchors.fill: parent
        anchors.margins: 8
        anchors.leftMargin: 36
        spacing: 12
        
        // Action prefix icon
        Text {
            id: actionPrefix
            anchors.verticalCenter: parent.verticalCenter
            text: Fonts.iconChevronRight
            color: Colors.textSubdued
            font.pixelSize: Fonts.h5
            font.family: Fonts.iconFont
        }
        
        // Content container with flexible width and custom children
        Column {
            id: actionContent
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            width: parent.width - actionPrefix.width - parent.spacing
            
            Text {
                text: root.actionName
                color: Colors.text
                font.pixelSize: Fonts.p
                elide: Text.ElideRight
                width: parent.width
            }
        }
    }
}
