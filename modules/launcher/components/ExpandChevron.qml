pragma ComponentBehavior: Bound

import QtQuick
import qs.settings
import qs.components.animations

// Reusable animated chevron for expandable items
Item {
    id: root
    
    property bool expanded: false
    
    width: height
    
    Text {
        anchors.centerIn: parent
        text: Fonts.iconChevronRight
        color: Colors.textSubdued
        font.pixelSize: 12
        font.family: Fonts.iconFont
        
        AnimatedRotation on rotation {}
        
        rotation: root.expanded ? 90 : 0
    }
}
