/**
 * Wallpaper Component
 * 
 * Renders a wallpaper across all connected monitors with synchronized cross-fade transitions.
 * Creates one fullscreen window per screen and positions it on the Wayland background layer.
 * Uses a dual-image cross-fade pattern: the new wallpaper is preloaded into the inactive
 * layer, and all screens transition simultaneously when ready.
 * 
 * Architecture:
 * - Variants creates one PanelWindow per connected screen
 * - Each window contains two Image layers for the cross-fade effect
 * - WallpaperService manages state and notifies screens of new wallpapers
 * - Screen positioning accounts for multi-monitor virtual desktop coordinates
 * 
 * Usage:
 *   Wallpaper {
 *       // Automatically renders on all connected screens
 *       // Responds to WallpaperService wallpaper change events
 *   }
 */

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.settings
import qs.services

Scope {
    id: wallpaperScope
    reloadableId: "wallpaperModule"

    // Multi-screen rendering with one window per connected display
    Variants {
        id: screenVariants
        model: Quickshell.screens

        delegate: PanelWindow {
            id: wallpaperWindow

            // Capture screen reference early for stable access throughout component lifecycle
            required property var modelData

            // Fullscreen background window configuration
            screen: modelData
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Initialize Wayland layer configuration and register screen with service
            Component.onCompleted: {
                // Notify service that this screen is ready for wallpaper updates
                WallpaperService.registerScreen(modelData.name);

                // Configure Wayland layer shell for background rendering: place below all other windows
                if (WlrLayershell != null) {
                    WlrLayershell.layer = WlrLayer.Background;
                    WlrLayershell.keyboardFocus = WlrKeyboardFocus.None;
                }

                // Load current wallpaper at startup
                if (WallpaperService.currentWallpaperPath) {
                    image1.source = "file://" + WallpaperService.currentWallpaperPath;
                }
            }

            // Virtual desktop dimensions for multi-monitor coordinate system (cached)
            property real totalDesktopWidth: WallpaperSize.totalDesktopWidth
            property real totalDesktopHeight: WallpaperSize.totalDesktopHeight
            
            // Current screen coordinates and dimensions (cached from ScreenGeometry service)
            property var screenGeom: ScreenGeometry.getGeometry(modelData.name)
            property real screenX: screenGeom.x
            property real screenY: screenGeom.y
            property real screenWidth: screenGeom.width
            property real screenHeight: screenGeom.height

            // Cross-fade layer toggle: when true, image1 is shown; when false, image2 is shown
            property bool useFirstImage: true

            // Current wallpaper path from service
            property string currentWallpaper: WallpaperService.currentWallpaperPath

            // Image1 positioning: scale and coordinates (primary display layer during fade-out)
            property real image1Scale: 1.0
            property real image1ScaledWidth: 0
            property real image1ScaledHeight: 0
            property real image1X: 0
            property real image1Y: 0

            // Image2 positioning: scale and coordinates (secondary display layer during fade-in)
            property real image2Scale: 1.0
            property real image2ScaledWidth: 0
            property real image2ScaledHeight: 0
            property real image2X: 0
            property real image2Y: 0

            // Cross-fade state machine: tracks which image is loading and when to trigger transition
            property bool waitingForImageLoad: false
            property bool targetIsImage2: false

            // Calculate image positioning for virtual desktop coordinate system: scales and positions
            // image to cover entire desktop, accounting for multi-monitor layout and screen offset
            function calculatePositioning(sourceWidth, sourceHeight, isImage1) {
                if (sourceWidth <= 0 || sourceHeight <= 0) return;

                // Calculate scale to cover entire desktop
                var scaleX = totalDesktopWidth / sourceWidth;
                var scaleY = totalDesktopHeight / sourceHeight;
                var scale = Math.max(scaleX, scaleY);

                // Calculate scaled dimensions
                var scaledWidth = sourceWidth * scale;
                var scaledHeight = sourceHeight * scale;

                // Calculate offset to center on virtual desktop
                var imageOffsetX = (totalDesktopWidth - scaledWidth) / 2;
                var imageOffsetY = (totalDesktopHeight - scaledHeight) / 2;

                // Calculate final position for this screen
                var finalX = -(screenX - imageOffsetX);
                var finalY = -(screenY - imageOffsetY);

                // Update the appropriate image's properties
                if (isImage1) {
                    image1Scale = scale;
                    image1ScaledWidth = scaledWidth;
                    image1ScaledHeight = scaledHeight;
                    image1X = finalX;
                    image1Y = finalY;
                } else {
                    image2Scale = scale;
                    image2ScaledWidth = scaledWidth;
                    image2ScaledHeight = scaledHeight;
                    image2X = finalX;
                    image2Y = finalY;
                }
            }

            // Background container with two image layers for cross-fade effect
            Rectangle {
                anchors.fill: parent
                color: Colors.bg  // Fallback background color during image loading

                // Primary image layer: shown when useFirstImage is true, fades out during transition
                Image {
                    id: image1
                    source: ""
                    width: wallpaperWindow.image1ScaledWidth
                    height: wallpaperWindow.image1ScaledHeight
                    x: wallpaperWindow.image1X
                    y: wallpaperWindow.image1Y

                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    antialiasing: true
                    cache: false
                    asynchronous: true

                    // Opacity animates from 1.0 to 0.0 when transitioning to image2
                    opacity: wallpaperWindow.useFirstImage ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: WallpaperService.transitionDuration
                            easing.type: Easing.InOutQuad
                        }
                    }

                    // Calculate positioning once image dimensions are known
                    onStatusChanged: {
                        if (status === Image.Ready) {
                            wallpaperWindow.calculatePositioning(sourceSize.width, sourceSize.height, true);
                        }
                    }
                }

                // Secondary image layer: shown when useFirstImage is false, fades in during transition
                Image {
                    id: image2
                    source: ""
                    width: wallpaperWindow.image2ScaledWidth
                    height: wallpaperWindow.image2ScaledHeight
                    x: wallpaperWindow.image2X
                    y: wallpaperWindow.image2Y

                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    antialiasing: true
                    cache: false
                    asynchronous: true

                    // Opacity animates from 0.0 to 1.0 when transitioning to image2
                    opacity: wallpaperWindow.useFirstImage ? 0.0 : 1.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: WallpaperService.transitionDuration
                            easing.type: Easing.InOutQuad
                        }
                    }

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            wallpaperWindow.calculatePositioning(sourceSize.width, sourceSize.height, false);
                        }
                    }
                }
            }

            // Listen for wallpaper changes from service and pre-load into inactive image layer
            Connections {
                target: WallpaperService

                function onWallpaperChanged(newPath) {
                    if (!newPath) return;

                    // Determine target layer: if image1 is showing, load new wallpaper into image2 and vice versa
                    wallpaperWindow.targetIsImage2 = wallpaperWindow.useFirstImage;
                    wallpaperWindow.waitingForImageLoad = true;

                    // Load the new wallpaper into the inactive image layer for smooth cross-fade
                    if (wallpaperWindow.targetIsImage2) {
                        image2.source = newPath;
                        // Check if image was cached in memory (already loaded before)
                        if (image2.status === Image.Ready) {
                            wallpaperWindow.waitingForImageLoad = false;
                            WallpaperService.reportScreenReady(wallpaperWindow.modelData.name);
                        }
                    } else {
                        image1.source = newPath;
                        // Check if image was cached in memory (already loaded before)
                        if (image1.status === Image.Ready) {
                            wallpaperWindow.waitingForImageLoad = false;
                            WallpaperService.reportScreenReady(wallpaperWindow.modelData.name);
                        }
                    }
                }
            }

            // Monitor image1 status: when loaded and image1 is the target, notify service ready
            Connections {
                target: image1

                function onStatusChanged() {
                    if (wallpaperWindow.waitingForImageLoad && !wallpaperWindow.targetIsImage2 && image1.status === Image.Ready) {
                        wallpaperWindow.waitingForImageLoad = false;
                        WallpaperService.reportScreenReady(wallpaperWindow.modelData.name);
                    }
                }
            }

            // Monitor image2 status: when loaded and image2 is the target, notify service ready
            Connections {
                target: image2

                function onStatusChanged() {
                    if (wallpaperWindow.waitingForImageLoad && wallpaperWindow.targetIsImage2 && image2.status === Image.Ready) {
                        wallpaperWindow.waitingForImageLoad = false;
                        WallpaperService.reportScreenReady(wallpaperWindow.modelData.name);
                    }
                }
            }

            // Synchronize cross-fade transition across all screens: when all are ready, animate simultaneously
            Connections {
                target: WallpaperService

                function onAllScreensReady() {
                    // Perform the synchronized transition: toggle useFirstImage to trigger all screens' Behaviors
                    wallpaperWindow.useFirstImage = !wallpaperWindow.targetIsImage2;
                }
            }
        }
    }
}
