pragma Singleton
import QtQuick
import Quickshell

/**
 * ScreenGeometry Service
 * 
 * Caches screen geometry (position and dimensions) for all connected monitors.
 * Calculates once on startup and recalculates when screens change (hot-plug events).
 * 
 * This avoids creating reactive property bindings in every PanelWindow instance,
 * significantly reducing overhead when multiple windows reference the same screen data.
 * 
 * Usage:
 *   const geom = ScreenGeometry.getGeometry(screenName);
 *   property real screenX: geom.x
 *   property real screenY: geom.y
 *   property real screenWidth: geom.width
 *   property real screenHeight: geom.height
 */
Singleton {
    id: root
    
    // Cache of screen geometries indexed by screen name
    // Structure: { "screenName": { x, y, width, height, name } }
    property var screenGeometries: ({})
    
    /**
     * Recalculate and cache geometry for all connected screens.
     * Called on startup and whenever screens change.
     */
    function recalculate() {
        var geometries = {};
        
        for (let screen of Quickshell.screens) {
            geometries[screen.name] = {
                x: screen.x,
                y: screen.y,
                width: screen.width,
                height: screen.height,
                name: screen.name
            };
        }
        
        screenGeometries = geometries;
    }
    
    /**
     * Get cached geometry for a specific screen by name.
     * Returns a geometry object with x, y, width, height, and name.
     * Falls back to default 1920x1080 geometry if screen not found.
     * 
     * @param screenName - The name/identifier of the screen
     * @returns Object with x, y, width, height, name properties
     */
    function getGeometry(screenName) {
        return screenGeometries[screenName] || {
            x: 0,
            y: 0,
            width: 1920,
            height: 1080,
            name: screenName || "unknown"
        };
    }
    
    // Calculate geometry on service initialization
    Component.onCompleted: {
        recalculate();
    }
    
    // Recalculate when screens are added, removed, or reconfigured
    Connections {
        target: Quickshell
        
        function onScreensChanged() {
            root.recalculate();
        }
    }
}
