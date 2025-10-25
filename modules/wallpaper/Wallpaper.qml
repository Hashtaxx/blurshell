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

            // Initialize Wayland layer configuration
            Component.onCompleted: {
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

            // Current screen geometry (fetched from service, updates reactively)
            property var screenGeom: ScreenGeometry.getGeometry(modelData.name)

            // Cross-fade layer toggle: when true, image1 is shown; when false, image2 is shown
            property bool useFirstImage: true

            // Image positioning stored as objects to reduce property overhead
            property var image1Position: ({ scale: 1.0, x: 0, y: 0, width: 0, height: 0 })
            property var image2Position: ({ scale: 1.0, x: 0, y: 0, width: 0, height: 0 })

            // Cross-fade state machine: tracks which image is loading and when to trigger transition
            property bool waitingForImageLoad: false
            property bool targetIsImage2: false

            // Calculate positioning for an image
            function calculatePosition(sourceWidth, sourceHeight) {
                return ScreenGeometry.calculateScreenPositioning(
                    sourceWidth, 
                    sourceHeight, 
                    screenGeom.x, 
                    screenGeom.y
                );
            }

            // Recalculate positioning when screen geometry or images change
            function recalculatePositions() {
                if (image1.status === Image.Ready && image1.source !== "") {
                    image1Position = calculatePosition(image1.sourceSize.width, image1.sourceSize.height);
                }
                if (image2.status === Image.Ready && image2.source !== "") {
                    image2Position = calculatePosition(image2.sourceSize.width, image2.sourceSize.height);
                }
            }

            // React to screen geometry changes
            onScreenGeomChanged: recalculatePositions()

            // Background container with two image layers for cross-fade effect
            Rectangle {
                anchors.fill: parent
                color: Colors.bg  // Fallback background color during image loading

                // Primary image layer: shown when useFirstImage is true, fades out during transition
                Image {
                    id: image1
                    source: ""
                    width: wallpaperWindow.image1Position.scaledWidth
                    height: wallpaperWindow.image1Position.scaledHeight
                    x: wallpaperWindow.image1Position.x
                    y: wallpaperWindow.image1Position.y

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
                            wallpaperWindow.image1Position = wallpaperWindow.calculatePosition(sourceSize.width, sourceSize.height);
                        }
                    }
                }

                // Secondary image layer: shown when useFirstImage is false, fades in during transition
                Image {
                    id: image2
                    source: ""
                    width: wallpaperWindow.image2Position.scaledWidth
                    height: wallpaperWindow.image2Position.scaledHeight
                    x: wallpaperWindow.image2Position.x
                    y: wallpaperWindow.image2Position.y

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
                            wallpaperWindow.image2Position = wallpaperWindow.calculatePosition(sourceSize.width, sourceSize.height);
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

            // Recalculate positioning when screen geometry changes
            Connections {
                target: ScreenGeometry

                function onScreenGeometriesChanged() {
                    wallpaperWindow.screenGeom = ScreenGeometry.getGeometry(wallpaperWindow.modelData.name);
                    wallpaperWindow.recalculatePositions();
                }
            }

            // Recalculate positioning when desktop dimensions change (e.g., multi-monitor configuration)
            Connections {
                target: ScreenGeometry

                function onTotalDesktopWidthChanged() {
                    wallpaperWindow.recalculatePositions();
                }

                function onTotalDesktopHeightChanged() {
                    wallpaperWindow.recalculatePositions();
                }
            }
        }
    }
}
