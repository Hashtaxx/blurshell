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
    required property real totalDesktopWidth
    required property real totalDesktopHeight
    required property real screenX
    required property real screenY
    required property real screenWidth
    required property real screenHeight
    
    // ============ OPTIONAL PROPERTIES ============
    property real sourceImageWidth: 0
    property real sourceImageHeight: 0
    property int blurRadius: 64
    property bool showBlur: true
    property real darkenOpacity: 0.3
    
    // ============ COMPUTED PROPERTIES ============
    // Resolved source dimensions (use provided values or fallback to loaded image size)
    readonly property real actualSourceWidth: sourceImageWidth > 0 ? sourceImageWidth : wallpaperImage.sourceSize.width
    readonly property real actualSourceHeight: sourceImageHeight > 0 ? sourceImageHeight : wallpaperImage.sourceSize.height
    
    // Scale factors to cover total desktop
    readonly property real scaleX: actualSourceWidth > 0 ? totalDesktopWidth / actualSourceWidth : 1.0
    readonly property real scaleY: actualSourceHeight > 0 ? totalDesktopHeight / actualSourceHeight : 1.0
    readonly property real wallpaperScale: Math.max(scaleX, scaleY)
    
    // Scaled dimensions after applying cover scale
    readonly property real wallpaperScaledWidth: actualSourceWidth * wallpaperScale
    readonly property real wallpaperScaledHeight: actualSourceHeight * wallpaperScale
    
    // Centering offset for scaled wallpaper within total desktop
    readonly property real imageOffsetX: (totalDesktopWidth - wallpaperScaledWidth) / 2
    readonly property real imageOffsetY: (totalDesktopHeight - wallpaperScaledHeight) / 2
    
    // Position within this monitor's viewport
    readonly property real wallpaperX: -(screenX - imageOffsetX)
    readonly property real wallpaperY: -(screenY - imageOffsetY)
    
    // ============ WALLPAPER SOURCE ============
    readonly property string wallpaperUrl: WallpaperService.currentWallpaperPath ? "file://" + WallpaperService.currentWallpaperPath : ""

    clip: true

    // ============ WALLPAPER IMAGE ============
    // Single image component used for both direct display and blur source.
    // Visibility and rendering mode controlled by showBlur property.
    Image {
        id: wallpaperImage
        x: root.wallpaperX
        y: root.wallpaperY
        width: root.wallpaperScaledWidth
        height: root.wallpaperScaledHeight
        
        source: root.wallpaperUrl
        fillMode: Image.Stretch
        smooth: true
        antialiasing: true
        cache: true
        asynchronous: false  // Keep synchronous to avoid flicker on lock screen
        visible: !root.showBlur
    }
    
    // ============ BLUR EFFECT ============
    // FastBlur effect using the single wallpaper image as source.
    // Only visible when showBlur is enabled.
    FastBlur {
        x: root.wallpaperX
        y: root.wallpaperY
        width: root.wallpaperScaledWidth
        height: root.wallpaperScaledHeight
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
}
