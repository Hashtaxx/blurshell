pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.settings
import qs.services
import qs.modules.bar.components
import qs.components.animations

Background {
    id: root
    
    implicitWidth: volumeContent.width + padding
    visible: (Config.showVolumeBarAlways || showTimer.running || root.opacity > 0) && (!AppState.controlCenterVisible || Config.showVolumeBarAlways)
    opacity: Config.showVolumeBarAlways ? 1.0 : (showTimer.running && !AppState.controlCenterVisible ? 1.0 : 0.0)
    
    // Custom opacity animation: slower fade-in, faster fade-out
    AnimatedOpacity on opacity {
        animationDuration: root.opacity === 1.0 ? AnimationConfig.slow : AnimationConfig.fast
        animationEasing: root.opacity === 1.0 ? Easing.OutQuad : Easing.InOutQuad
    }
    
    // Auto-hide timer: shows volume bar temporarily after volume changes (unless always visible)
    Timer {
        id: showTimer
        interval: 3000
        running: false
        repeat: false
    }
    
    // Watch for volume changes
    Connections {
        target: Audio
        function onVolumeChanged() {
            if (!Config.showVolumeBarAlways && !AppState.controlCenterVisible) {
                showTimer.restart();
            }
        }
        function onMutedChanged() {
            if (!Config.showVolumeBarAlways && !AppState.controlCenterVisible) {
                showTimer.restart();
            }
        }
    }
    
    // Hide immediately when Control Center opens
    Connections {
        target: AppState
        function onControlCenterVisibleChanged() {
            if (AppState.controlCenterVisible && !Config.showVolumeBarAlways) {
                showTimer.stop();
            }
        }
    }
    
    Row {
        id: volumeContent
        anchors.centerIn: parent
        spacing: 12
        height: parent.height
        
        // Volume icon
        Text {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            width: icon.height
            text: Audio.volumeIcon
            font.family: Fonts.iconFont
            font.pixelSize: icon.width
            verticalAlignment: Text.AlignVCenter
            color: Audio.muted ? Colors.red : Colors.text
            
            AnimatedColor on color {}
        }
        
        // Volume bar container
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 80
            height: parent.height * 0.5
            
            ClippingRectangle {
                id: volumeBar
                anchors.fill: parent
                
                radius: 8
                color: Colors.brighten_3
                
                // Prevents animation jank during user drag interactions
                property bool userInteracting: false
                // Prevents initial animation on component load - only animate after first real volume change
                property bool animationsReady: false
                property real lastVolume: Audio.volume
                
                AnimatedColor on color {}
                
                // Enable animations only after the first actual volume change (prevents startup animation)
                Connections {
                    target: Audio
                    function onVolumeChanged() {
                        if (volumeBar.lastVolume !== Audio.volume) {
                            volumeBar.animationsReady = true;
                            volumeBar.lastVolume = Audio.volume;
                        }
                    }
                }
                
                // Volume fill bar
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.max(0, Math.min(1, Audio.volume))
                    color: Audio.muted ? Qt.alpha(Config.controlCenterAccent, 0.3) : Config.controlCenterAccent
                    
                    AnimatedWidth on width {
                        enabled: !volumeBar.userInteracting && volumeBar.animationsReady
                        animationDuration: AnimationConfig.fast
                    }
                    
                    AnimatedColor on color {}
                }
                
                // Interactive volume control - click and drag to adjust volume
                MouseArea {
                    anchors.fill: parent
                    enabled: !Audio.muted
                    hoverEnabled: true
                    cursorShape: Audio.muted ? Qt.ArrowCursor : Qt.PointingHandCursor
                    
                    // Debounce volume updates to prevent excessive Audio service calls
                    property real lastSetVolume: -1
                    
                    onPressed: (mouse) => {
                        volumeBar.userInteracting = true;
                        lastSetVolume = -1;
                        updateVolume(mouse.x);
                        if (!Config.showVolumeBarAlways && !AppState.controlCenterVisible) {
                            showTimer.restart();
                        }
                    }
                    
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            updateVolume(mouse.x);
                        }
                    }
                    
                    onReleased: {
                        volumeBar.userInteracting = false;
                        lastSetVolume = -1;
                    }
                    
                    onEntered: {
                        if (!Audio.muted) {
                            volumeBar.color = Colors.brighten_5;
                        }
                    }
                    
                    onExited: {
                        volumeBar.color = Colors.brighten_3;
                    }
                    
                    // Convert mouse position to volume value (0.0 - 1.0)
                    function updateVolume(x: real): void {
                        const rawVolume = Math.max(0, Math.min(1, x / width));
                        const roundedVolume = Math.round(rawVolume * 100) / 100;
                        
                        // Only update if volume actually changed (prevents redundant service calls)
                        if (roundedVolume !== lastSetVolume) {
                            lastSetVolume = roundedVolume;
                            Audio.setVolume(roundedVolume);
                        }
                    }
                }
            }
        }
    }
    
    // Middle-click anywhere on volume bar to toggle mute
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                Audio.toggleMute();
                if (!Config.showVolumeBarAlways && !AppState.controlCenterVisible) {
                    showTimer.restart();
                }
            }
        }
    }
}
