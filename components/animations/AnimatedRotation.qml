pragma ComponentBehavior: Bound

import QtQuick

Behavior {
    id: root
    
    // Customizable properties - can be overridden when used
    property int animationDuration: AnimationConfig.defaultDuration
    property int animationEasing: AnimationConfig.defaultEasing
    property bool enabled: AnimationConfig.animationsEnabled
    
    RotationAnimation {
        duration: root.enabled ? root.animationDuration : 0
        easing.type: root.animationEasing
        direction: RotationAnimation.Shortest
    }
}
