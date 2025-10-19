pragma ComponentBehavior: Bound

import QtQuick
import qs.settings
import qs.modules.launcher
import qs.components.animations

// Reusable list item with selection state and animation
Item {
    id: root
    
    property bool selected: false
    property alias content: contentItem.children
    
    width: parent.width
    height: LauncherConfig.listItemHeight
    
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.selected ? Colors.brighten_10 : "transparent"
        border.width: 0
        
        AnimatedColor on color {
            animationDuration: AnimationConfig.fast
        }
    }
    
    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: 12
    }
}
