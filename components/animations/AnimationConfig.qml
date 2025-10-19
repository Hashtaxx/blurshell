pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Global animation settings for consistent feel across the app
    
    // Duration presets (in milliseconds)
    readonly property int instant: 0
    readonly property int fast: 100
    readonly property int normal: 200
    readonly property int slow: 300
    readonly property int verySlow: 500
    
    // Default duration used by most animations
    readonly property int defaultDuration: normal
    
    // Easing curves
    readonly property int defaultEasing: Easing.OutCubic
    readonly property int smoothEasing: Easing.InOutQuad
    readonly property int snapEasing: Easing.OutBack
    readonly property int elasticEasing: Easing.OutElastic
    
    // Enable/disable all animations globally (useful for accessibility or testing)
    property bool animationsEnabled: true
    
    // Helper function to get effective duration
    function duration(customDuration: int): int {
        return animationsEnabled ? (customDuration >= 0 ? customDuration : defaultDuration) : 0;
    }
}
