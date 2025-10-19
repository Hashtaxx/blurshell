// Popup.qml
// Basic popup window wrapper with configurable background color and optional animations
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.settings
import qs.components.animations

PopupWindow {
    id: root
    
    property color backgroundColor: Colors.bg

    visible: false
    color: "transparent"

    implicitWidth: 300
    implicitHeight: 400

    Rectangle {
        id: bg
        anchors.fill: parent
        color: root.backgroundColor
        radius: Config.windowRounding
        
        // Popup animations
        opacity: root.visible ? 1.0 : 0.0
        transformOrigin: Item.Top
        
        AnimatedOpacity on opacity {
            animationDuration: AnimationConfig.normal
        }
    }
}
