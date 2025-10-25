pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.settings
import qs.services
import qs.modules.lockscreen.components

// LockscreenOverlay: Full-screen blurred wallpaper that fades in/out
ShellRoot {
    id: overlayRoot

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: overlayWindow
            required property var modelData
            
            screen: modelData
            exclusionMode: ExclusionMode.Ignore
            
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"

            // Cache screen geometry to avoid repeated property bindings
            property var screenGeom: ScreenGeometry.getGeometry(modelData.name)

            // Wayland layer configuration
            Component.onCompleted: {
                if (this.WlrLayershell != null) {
                    this.WlrLayershell.layer = WlrLayer.Overlay;
                    this.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive;
                }
            }

            // Background container
            Rectangle {
                id: background
                anchors.fill: parent
                color: Colors.bgDark
                
                // Fade in when overlay becomes visible
                opacity: AppState.preLockOverlayVisible ? 1.0 : 0.0
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                // Blurred wallpaper using the reusable component
                BlurredWallpaper {
                    anchors.fill: parent
                    screenX: overlayWindow.screenGeom.x
                    screenY: overlayWindow.screenGeom.y
                    screenWidth: overlayWindow.screenGeom.width
                    screenHeight: overlayWindow.screenGeom.height
                    blurRadius: 64
                    showBlur: true
                    darkenOpacity: AppState.preLockOverlayVisible ? Config.lockscreenDimming : 0.0
                    
                    Behavior on darkenOpacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
