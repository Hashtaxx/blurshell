pragma Singleton
import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root
    
    property var screenGeometries: ({})
    
    // Total desktop dimensions (merged from WallpaperSize)
    property int totalDesktopWidth: 0
    property int totalDesktopHeight: 0
    property int desktopMinX: 0
    property int desktopMinY: 0
    
    function recalculate() {
        var geometries = {};
        var firstScreen = true;
        var minX = 0;
        var maxX = 0;
        var minY = 0;
        var maxY = 0;
        
        for (let screen of Quickshell.screens) {
            geometries[screen.name] = {
                x: screen.x,
                y: screen.y,
                width: screen.width,
                height: screen.height,
                name: screen.name
            };
            
            // Calculate total desktop bounds
            var left = screen.x;
            var right = screen.x + screen.width;
            var top = screen.y;
            var bottom = screen.y + screen.height;

            if (firstScreen) {
                minX = left;
                maxX = right;
                minY = top;
                maxY = bottom;
                firstScreen = false;
            } else {
                if (left < minX) minX = left;
                if (right > maxX) maxX = right;
                if (top < minY) minY = top;
                if (bottom > maxY) maxY = bottom;
            }
        }
        
        screenGeometries = geometries;
        desktopMinX = minX;
        desktopMinY = minY;
        totalDesktopWidth = maxX - minX;
        totalDesktopHeight = maxY - minY;
    }
    
    function getGeometry(screenName) {
        return screenGeometries[screenName] || {
            x: 0,
            y: 0,
            width: 1920,
            height: 1080,
            name: screenName || "unknown"
        };
    }
    
    function calculateScreenPositioning(sourceWidth, sourceHeight, screenX, screenY) {
        if (sourceWidth <= 0 || sourceHeight <= 0) {
            return { scale: 1, x: 0, y: 0, scaledWidth: 0, scaledHeight: 0 };
        }

        var scaleX = totalDesktopWidth / sourceWidth;
        var scaleY = totalDesktopHeight / sourceHeight;
        var scale = Math.max(scaleX, scaleY);

        var scaledWidth = sourceWidth * scale;
        var scaledHeight = sourceHeight * scale;

        var imageOffsetX = (totalDesktopWidth - scaledWidth) / 2;
        var imageOffsetY = (totalDesktopHeight - scaledHeight) / 2;

        var finalX = imageOffsetX - (screenX - desktopMinX);
        var finalY = imageOffsetY - (screenY - desktopMinY);

        return {
            scale: scale,
            x: finalX,
            y: finalY,
            scaledWidth: scaledWidth,
            scaledHeight: scaledHeight
        };
    }
    
    Component.onCompleted: {
        recalculate();
    }
    
    Connections {
        target: Quickshell
        
        function onScreensChanged() {
            root.recalculate();
        }
    }

    Connections {
        target: HyprStats

        function onMonitorConfigChanged(eventName) {
            delayedRecalculateTimer.restart();
        }
    }

    Timer {
        id: delayedRecalculateTimer
        interval: 100
        repeat: false
        onTriggered: {
            root.recalculate();
        }
    }
}
