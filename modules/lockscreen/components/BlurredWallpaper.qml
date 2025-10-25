pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.services
import qs.components.animations

/**
 * BlurredWallpaper
 *
 * Renders a stretched and blurred wallpaper across multiple monitors.
 * Automatically handles scaling to cover total desktop dimensions while
 * maintaining aspect ratio. Supports dynamic blur toggling and darkening overlay.
 *
 * Usage: Provide monitor geometry (screenX/Y, screenWidth/Height) and total
 * desktop dimensions. The component clips content to the monitor boundaries.
 */
Item {
    id: root
    
    // ============ REQUIRED PROPERTIES ============
    required property real screenX
    required property real screenY
    required property real screenWidth
    required property real screenHeight
    
    // ============ OPTIONAL PROPERTIES ============
    property int blurRadius: 64
    property bool showBlur: true
    property real darkenOpacity: 0.3
    
    // ============ POSITIONING ============
    // Calculate positioning using the centralized ScreenGeometry service
    property var imagePosition: calculatePosition()
    
    function calculatePosition() {
        if (wallpaperImage.status === Image.Ready && wallpaperImage.sourceSize.width > 0) {
            return ScreenGeometry.calculateScreenPositioning(
                wallpaperImage.sourceSize.width,
                wallpaperImage.sourceSize.height,
                screenX,
                screenY
            );
        }
        return { scale: 1, x: 0, y: 0, scaledWidth: 0, scaledHeight: 0 };
    }
    
    // Recalculate when screen position changes
    onScreenXChanged: { if (wallpaperImage.status === Image.Ready) imagePosition = calculatePosition(); }
    onScreenYChanged: { if (wallpaperImage.status === Image.Ready) imagePosition = calculatePosition(); }
    
    // ============ WALLPAPER SOURCE ============
    readonly property string wallpaperUrl: WallpaperService.currentWallpaperPath ? "file://" + WallpaperService.currentWallpaperPath : ""

    clip: true

    // ============ WALLPAPER IMAGE ============
    // Single image component used for both direct display and blur source.
    // Visibility and rendering mode controlled by showBlur property.
    Image {
        id: wallpaperImage
        x: root.imagePosition.x
        y: root.imagePosition.y
        width: root.imagePosition.scaledWidth
        height: root.imagePosition.scaledHeight
        
        source: root.wallpaperUrl
        fillMode: Image.Stretch
        smooth: true
        antialiasing: true
        cache: true
        asynchronous: false  // Keep synchronous to avoid flicker on lock screen
        visible: !root.showBlur
        
        // Recalculate position when image loads
        onStatusChanged: {
            if (status === Image.Ready) {
                root.imagePosition = root.calculatePosition();
            }
        }
    }
    
    // ============ BLUR EFFECT ============
    // FastBlur effect using the single wallpaper image as source.
    // Only visible when showBlur is enabled.
    FastBlur {
        x: root.imagePosition.x
        y: root.imagePosition.y
        width: root.imagePosition.scaledWidth
        height: root.imagePosition.scaledHeight
        radius: root.blurRadius
        visible: root.showBlur
        
        source: ShaderEffectSource {
            sourceItem: wallpaperImage
            hideSource: true
        }
    }
    
    // ============ DARKENING OVERLAY ============
    // Semi-transparent black layer for improved readability on top of wallpaper
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.darkenOpacity
    }
    
    // ============ REACTIVE UPDATES ============
    // Recalculate positioning when desktop geometry changes
    Connections {
        target: ScreenGeometry
        
        function onTotalDesktopWidthChanged() {
            if (wallpaperImage.status === Image.Ready) {
                root.imagePosition = root.calculatePosition();
            }
        }
        
        function onTotalDesktopHeightChanged() {
            if (wallpaperImage.status === Image.Ready) {
                root.imagePosition = root.calculatePosition();
            }
        }
    }
    
    // Recalculate when wallpaper changes
    Connections {
        target: WallpaperService
        
        function onWallpaperChanged() {
            // Image will recalculate on statusChanged when new image loads
        }
    }
}
