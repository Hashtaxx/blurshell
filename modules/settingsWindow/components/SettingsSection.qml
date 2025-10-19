/**
 * SettingsSection Component
 * 
 * Collapsible section container for organizing settings into titled, expandable groups.
 * Displays a clickable header with icon and title, toggles visibility of content.
 * Provides smooth animations for expand/collapse transitions.
 * 
 * Usage:
 *   SettingsSection {
 *       title: "Display Settings"
 *       icon: Fonts.iconMonitor
 *       expanded: true
 *       
 *       LineSetting {
 *           label.text: "Brightness"
 *           // control content here
 *       }
 *   }
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.settings
import qs.components.animations

Item {
    id: root
    
    // Layout configuration
    property string title: "Section Title"
    property string icon: Fonts.iconSettings
    property bool expanded: true
    property alias content: contentContainer.children
    
    // Layout dimensions
    readonly property int headerHeight: 44
    readonly property int cornerRadius: 6
    readonly property int horizontalMargin: 12
    readonly property int verticalSpacing: 8
    readonly property int sectionSpacing: 16
    readonly property int headerIconSize: Fonts.h4
    readonly property int chevronIconSize: Fonts.h5
    
    // Animation timing (from qs.components.animations.AnimationConfig)
    readonly property int expandDuration: AnimationConfig.normal
    readonly property int colorAnimDuration: AnimationConfig.fast
    
    width: parent.width
    height: expanded ? headerHeight + contentContainer.height + sectionSpacing : headerHeight
    
    Behavior on height {
        NumberAnimation {
            duration: root.expandDuration
            easing.type: Easing.InOutQuad
        }
    }

    Column {
        anchors.fill: parent
        spacing: root.verticalSpacing
        
        // Clickable section header with icon, title, and expand/collapse indicator
        Rectangle {
            id: headerRect
            width: parent.width
            height: root.headerHeight
            radius: root.cornerRadius
            color: root.expanded ? Colors.brighten_5 : Colors.brighten_3
            
            Behavior on color {
                ColorAnimation {
                    duration: root.colorAnimDuration
                }
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.horizontalMargin
                anchors.rightMargin: root.horizontalMargin
                spacing: root.horizontalMargin
                
                // Section icon
                Text {
                    text: root.icon
                    font.pixelSize: root.headerIconSize
                    color: Colors.text
                    font.family: Fonts.iconFont
                }
                
                // Section title
                Text {
                    text: root.title
                    font.pixelSize: root.headerIconSize
                    color: Colors.text
                    Layout.fillWidth: true
                }
                
                // Expand/collapse chevron indicator
                Text {
                    text: root.expanded ? Fonts.iconChevronUp : Fonts.iconChevronDown
                    font.pixelSize: root.chevronIconSize
                    color: Colors.textSecondary
                    font.family: Fonts.iconFont
                    
                    Behavior on rotation {
                        NumberAnimation {
                            duration: root.expandDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
        }
        
        // Content container: shows/hides child components with animation
        Column {
            id: contentContainer
            width: parent.width
            spacing: root.verticalSpacing
            visible: root.expanded
            opacity: root.expanded ? 1 : 0
            
            Behavior on opacity {
                NumberAnimation {
                    duration: root.colorAnimDuration
                }
            }
        }
    }
}
