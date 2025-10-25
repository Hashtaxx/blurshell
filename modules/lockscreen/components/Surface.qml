pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.settings
import qs.services
import qs.components.animations

/**
 * Surface
 *
 * Renders the lock screen UI for a single monitor. Only the main monitor displays
 * interactive elements (time, date, password input, splash text). Secondary monitors
 * show only the blurred wallpaper background.
 *
 * Handles password input with real-time validation feedback, focus management,
 * and keyboard shortcuts (Escape to clear).
 *
 * Requires: context (LockContext) and screenInfo (monitor geometry data)
 */
Item {
    id: root
    
    // ============ REQUIRED PROPERTIES ============
    required property var context
    required property var screenInfo
    
    // ============ COMPUTED PROPERTIES ============
    // Determines if UI elements should be visible (only on main monitor)
    readonly property bool isMainMonitor: screenInfo?.name === Config.mainMonitorId

    // Cache screen geometry from service (screen might not be in geometry cache on first access, use fallback)
    property var screenGeom: screenInfo ? ScreenGeometry.getGeometry(screenInfo.name) : { x: 0, y: 0, width: 1920, height: 1080 }

    // ============ WALLPAPER BACKGROUND ============
    // Stretched and blurred wallpaper with darkening overlay for all monitors
    BlurredWallpaper {
        anchors.fill: parent
        screenX: root.screenGeom.x
        screenY: root.screenGeom.y
        screenWidth: root.screenGeom.width
        screenHeight: root.screenGeom.height
        blurRadius: 64
        showBlur: true
        darkenOpacity: Config.lockscreenDimming
    }

    // ============ INTERACTIVE UI LAYER ============
    // Input field, time display, and keyboard shortcuts (main monitor only)
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        visible: root.isMainMonitor
        
        onPressed: passwordInput.forceActiveFocus()
        
        // Keyboard shortcuts: Escape clears input, any key refocuses input field
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.context.clearInput();
            }
            passwordInput.forceActiveFocus();
        }

        // ============ MAIN LAYOUT ============
        Item {
            anchors.fill: parent

            // ============ TIME AND DATE DISPLAY ============
            // Positioned above password input; time has gradient, date is subdued
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: passwordBox.top
                anchors.bottomMargin: 160
                spacing: 20

                // ============ TIME DISPLAY ============
                // Large gradient text showing current time
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: timeText.width
                    height: timeText.height

                    Text {
                        id: timeText
                        text: Time.time
                        font.pixelSize: 128
                        font.weight: Font.Bold
                        visible: false
                    }

                    LinearGradient {
                        anchors.fill: timeText
                        source: timeText
                        start: Qt.point(0, 0)
                        end: Qt.point(timeText.width, timeText.height)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Colors.blue }
                            GradientStop { position: 0.3; color: Colors.mauve }
                            GradientStop { position: 0.7; color: Colors.pink }
                            GradientStop { position: 1.0; color: Colors.sky }
                        }
                    }
                }

                // ============ DATE DISPLAY ============
                // Smaller subdued text showing formatted date
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.fulldate
                    color: Colors.textSubdued
                    font.pixelSize: 22
                    font.weight: Font.Light
                }
            }

            // ============ PASSWORD INPUT FIELD ============
            // Rounded rectangle with animated border state feedback
            Rectangle {
                id: passwordBox
                anchors.centerIn: parent
                anchors.topMargin: 100
                width: 350
                height: 60
                color: Colors.darken_20
                border.width: 3
                radius: height / 2
                
                // Dynamic border color based on authentication state:
                // Red = authentication failed, Sky = active/typing, Blue = default
                border.color: {
                    if (root.context.showFailure) {
                        return Colors.red;
                    }
                    if (passwordInput.activeFocus || root.context.currentText.length > 0) {
                        return Colors.sky;
                    }
                    return Colors.blue;
                }
                
                // Smooth color transitions using animation config
                Behavior on border.color {
                    ColorAnimation {
                        duration: AnimationConfig.normal
                        easing.type: AnimationConfig.defaultEasing
                    }
                }

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 30
                    anchors.rightMargin: 30
                    color: Colors.text
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    enabled: !root.context.unlockInProgress
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    focus: true

                    onAccepted: root.context.tryUnlock()
                    onTextChanged: root.context.currentText = text

                    // Maintain focus to prevent keyboard dismissal and ensure input capture
                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            Qt.callLater(function() {
                                if (visible && enabled) {
                                    forceActiveFocus();
                                }
                            });
                        }
                    }

                    // Synchronize input text with shared context for cross-monitor coherence
                    Connections {
                        target: root.context
                        function onCurrentTextChanged() {
                            if (passwordInput.text !== root.context.currentText) {
                                passwordInput.text = root.context.currentText;
                            }
                        }
                    }
                }
            }

            // ============ SPLASH TEXT ============
            // System information or help text at bottom (configurable)
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 60
                width: passwordBox.width
                wrapMode: Text.WordWrap
                text: HyprStats.splash
                horizontalAlignment: Text.AlignHCenter
                color: Colors.textSubdued
                font.pixelSize: Fonts.p
                visible: Config.showSplashOnLockscreen
            }
        }
    }

    // ============ INITIALIZATION ============
    // Ensure password input has focus when component is fully loaded
    Component.onCompleted: {
        passwordInput.forceActiveFocus();
    }
}
