pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Cached desktop dimensions - calculated once on startup and when screens change
    property int totalDesktopWidth: 0
    property int totalDesktopHeight: 0

    // Calculate total desktop dimensions by finding the bounding box of all screens
    function recalculate() {
        var firstScreen = true;
        var minX = 0;
        var maxX = 0;
        var minY = 0;
        var maxY = 0;

        for (let screen of Quickshell.screens) {
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

        totalDesktopWidth = maxX - minX;
        totalDesktopHeight = maxY - minY;
    }

    // Calculate on startup
    Component.onCompleted: {
        recalculate();
    }

    // Recalculate when screens are added/removed or reconfigured
    Connections {
        target: Quickshell

        function onScreensChanged() {
            root.recalculate();
        }
    }
}
