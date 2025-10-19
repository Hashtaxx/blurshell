pragma ComponentBehavior: Bound

import QtQuick
import qs.components.animations

/**
 * Slide-in/slide-out animation with interactive drag-to-dismiss
 * 
 * Coordinates slide animations and drag interactions on a target item. Provides:
 * - Smooth fly-in animation with bounce effect
 * - Drag-to-dismiss gesture recognition and snap-back
 * - Multi-button mouse support for custom actions
 * 
 * Basic usage:
 *   DismissibleSlideAnimation {
 *       target: myItem
 *       onDismissed: cleanup()
 *   }
 *   component.startFlyIn()
 */
Item {
    id: root

    required property Item target
    
    anchors.fill: parent

    // Animation state
    property real slideOffset: 0
    property real dragDistance: 0
    property bool dismissing: false
    readonly property bool dragging: mouseArea.dragging
    
    // Gesture configuration
    property real dragThreshold: 100
    
    // Fly-in animation configuration
    property real flyInStartOffset: 420
    property real flyInOvershoot: -10
    property int flyInDuration: AnimationConfig.slow
    property int flyInBounceDuration: AnimationConfig.fast
    property int flyInOpacityDuration: AnimationConfig.normal
    
    // Dismiss animation configuration
    property real dismissEndOffset: 500
    property int dismissDuration: AnimationConfig.normal + 50
    property int dismissOpacityDuration: AnimationConfig.normal
    
    // Snap-back animation configuration
    property int snapBackDuration: AnimationConfig.normal
    
    // Signals for lifecycle and user interaction
    signal dismissed()
    signal flyInStarted()
    signal flyInCompleted()
    signal clicked(var mouse)
    signal rightClicked(var mouse)
    signal middleClicked(var mouse)
    
    // MouseArea for capturing and processing user interactions
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        propagateComposedEvents: true
        z: 0
        preventStealing: true
        
        // Drag tracking
        property real startX: 0
        property real startY: 0
        property real currentDragOffset: 0
        property bool dragging: false
        property bool isDragValid: false
        
        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton && !root.dismissing) {
                // Store absolute mouse position to handle transforms correctly
                var globalPos = mapToItem(null, mouse.x, mouse.y)
                startX = globalPos.x
                startY = globalPos.y
                currentDragOffset = 0
                dragging = true
                isDragValid = false
                // Halt all animations when user initiates drag
                root._flyInAnimation.stop()
                root._snapBackAnimation.stop()
                root._dismissAnimation.stop()
            }
        }
        
        onPositionChanged: (mouse) => {
            if (dragging && !root.dismissing) {
                // Use absolute coordinates to avoid feedback from transforms
                var globalPos = mapToItem(null, mouse.x, mouse.y)
                const diffX = globalPos.x - startX
                const diffY = Math.abs(globalPos.y - startY)
                
                // Require primarily horizontal movement; cancel if vertical exceeds threshold
                if (diffY > 30 && diffX < 20) {
                    dragging = false
                    isDragValid = false
                    root.startSnapBack()
                    return
                }
                
                // Mark as valid drag only after minimum movement threshold
                if (diffX > 5) {
                    isDragValid = true
                    currentDragOffset = diffX
                    root.dragDistance = Math.max(0, diffX)
                } else if (diffX < 0) {
                    // Prevent leftward drag
                    root.dragDistance = 0
                    currentDragOffset = 0
                }
            }
        }
        
        onReleased: (mouse) => {
            // Middle-click always triggers dismiss
            if (mouse.button === Qt.MiddleButton) {
                root.middleClicked(mouse)
                root.startDismiss()
                return
            }
            
            // Right-click for custom actions only
            if (mouse.button === Qt.RightButton) {
                root.rightClicked(mouse)
                return
            }
            
            // Left-click: decide between dismiss or snap-back
            if (mouse.button === Qt.LeftButton) {
                const shouldDismiss = isDragValid && root.shouldDismissOnDrag()
                
                dragging = false
                isDragValid = false
                
                if (shouldDismiss) {
                    root.startDismiss()
                } else if (root.dragDistance > 0) {
                    root.startSnapBack()
                }
            }
        }
        
        onExited: {
            // Auto-dismiss or snap-back if mouse leaves during active drag
            if (dragging && isDragValid) {
                const shouldDismiss = root.shouldDismissOnDrag()
                
                dragging = false
                isDragValid = false
                
                if (shouldDismiss) {
                    root.startDismiss()
                } else if (root.dragDistance > 0) {
                    root.startSnapBack()
                }
            }
        }
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.clicked(mouse)
            }
        }
    }
    
    // Apply horizontal slide transform to target item
    property Translate _transform: Translate {
        x: root.slideOffset + root.dragDistance
    }
    
    Component.onCompleted: {
        if (target) {
            target.transform = _transform
        }
    }
    
    // Fly-in animation: slides in from right with bounce effect and fade-in
    property SequentialAnimation _flyInAnimation: SequentialAnimation {
        id: flyInAnimation
        
        ScriptAction {
            script: {
                root.slideOffset = root.flyInStartOffset
                root.flyInStarted()
            }
        }
        
        // Main slide with opacity fade-in
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "slideOffset"
                from: root.flyInStartOffset
                to: root.flyInOvershoot
                duration: root.flyInDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root.target
                property: "opacity"
                from: 0
                to: 1
                duration: root.flyInOpacityDuration
            }
        }
        
        // Bounce back to final position (overshoot recovery)
        NumberAnimation {
            target: root
            property: "slideOffset"
            from: root.flyInOvershoot
            to: 0
            duration: root.flyInBounceDuration
            easing.type: Easing.OutCubic
        }
        
        ScriptAction {
            script: root.flyInCompleted()
        }
    }
    
    // Snap-back animation: returns item to neutral position when drag threshold not met
    property NumberAnimation _snapBackAnimation: NumberAnimation {
        id: snapBackAnimation
        target: root
        property: "dragDistance"
        to: 0
        duration: root.snapBackDuration
        easing.type: Easing.OutCubic
        
        // Capture current position as animation starting point
        onStarted: {
            from = root.dragDistance
        }
        
        // Ensure clean state after animation completes
        onStopped: {
            root.dragDistance = 0
        }
    }
    
    // Dismiss animation: slides out to right with fade-out
    property SequentialAnimation _dismissAnimation: SequentialAnimation {
        id: dismissAnimation
        
        ScriptAction {
            script: {
                root.dismissing = true
                root._flyInAnimation.stop()
                // Consolidate drag offset into slide offset to continue from current position
                root.slideOffset = root.slideOffset + root.dragDistance
                root.dragDistance = 0
            }
        }
        
        // Parallel slide-out and fade-out
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "slideOffset"
                to: root.dismissEndOffset
                duration: root.dismissDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root.target
                property: "opacity"
                to: 0
                duration: root.dismissOpacityDuration
            }
        }
        
        ScriptAction {
            script: root.dismissed()
        }
    }
    
    // Public API
    function startFlyIn() {
        if (!root._flyInAnimation.running) {
            root._flyInAnimation.start()
        }
    }
    
    function startDismiss() {
        if (!root._dismissAnimation.running && !mouseArea.dragging) {
            root._dismissAnimation.start()
        }
    }
    
    function startSnapBack() {
        if (!root._snapBackAnimation.running && !mouseArea.dragging && root.dragDistance > 0) {
            root._snapBackAnimation.start()
        }
    }
    
    function stopAnimations() {
        root._flyInAnimation.stop()
        root._dismissAnimation.stop()
        root._snapBackAnimation.stop()
    }
    
    function shouldDismissOnDrag() {
        return dragDistance > dragThreshold
    }
}