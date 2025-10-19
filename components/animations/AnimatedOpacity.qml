pragma ComponentBehavior: Bound

import QtQuick

Behavior {
    id: root
    
    // Customizable properties - can be overridden when used
    property int animationDuration: AnimationConfig.defaultDuration
    property int animationEasing: AnimationConfig.defaultEasing
    property bool enabled: AnimationConfig.animationsEnabled
    
    NumberAnimation {
        duration: root.enabled ? root.animationDuration : 0
        easing.type: root.animationEasing
    }
}
