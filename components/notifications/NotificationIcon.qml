pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.settings

/**
 * Unified notification icon component for both popups and notification center
 * 
 * Usage:
 * - For single notifications: shows notification image if available, otherwise app icon, fallback to bell
 * - For grouped notifications: shows only app icon (never notification image), fallback to bell
 * - Always shows bell icon if no other icon is available
 */
Item {
    id: root
    
    property string image: ""
    property string appIcon: ""
    property bool showImage: true
    
    implicitWidth: 48
    implicitHeight: 48
    
    readonly property bool hasImage: showImage && image && image.length > 0
    
    // Notification image (if present and showImage is true)
    Loader {
        id: imageLoader
        active: root.hasImage
        asynchronous: true
        anchors.fill: parent
        
        sourceComponent: Rectangle {
            radius: width / 2
            color: "transparent"
            clip: true
            
            Image {
                anchors.fill: parent
                source: {
                    // Don't prepend file:// if it's already an image:// provider URL
                    if (root.image.startsWith("image://")) {
                        return root.image
                    }
                    return "file://" + root.image
                }
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }
        }
    }
    
    // App icon or fallback bell (shown when no image, or as badge over image)
    Loader {
        id: appIconLoader
        active: true  // Always active to show bell fallback
        asynchronous: true
        
        // Positioning
        anchors.centerIn: root.hasImage ? undefined : parent
        anchors.right: root.hasImage ? parent.right : undefined
        anchors.bottom: root.hasImage ? parent.bottom : undefined
        anchors.rightMargin: root.hasImage ? -2 : 0
        anchors.bottomMargin: root.hasImage ? -2 : 0
        
        // Size
        width: root.hasImage ? parent.width * 0.45 : parent.width
        height: root.hasImage ? parent.height * 0.45 : parent.height
        
        sourceComponent: Rectangle {
            implicitWidth: appIconLoader.width
            implicitHeight: appIconLoader.height
            radius: width / 2
            color: Colors.brighten_10
            border.width: root.hasImage ? 2 : 1
            border.color: root.hasImage ? Colors.bg : Colors.brighten_20
            
            // Try to load as icon from theme
            Image {
                id: iconImage
                anchors.centerIn: parent
                // Use explicit pixel sizes instead of parent ratios
                width: root.hasImage ? 18 : 32
                height: root.hasImage ? 18 : 32
                visible: iconImage.source != ""
                
                source: Quickshell.iconPath(root.appIcon, true)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                sourceSize: Qt.size(width, height)
            }
            
            // Bell icon fallback (shown when no app icon or when app icon fails to load)
            Text {
                id: fallbackIcon
                anchors.centerIn: parent
                visible: iconImage.source == ""
                text: Fonts.iconBell
                font.family: Fonts.iconFont
                font.pixelSize: parent.height * 0.5
                color: Colors.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
