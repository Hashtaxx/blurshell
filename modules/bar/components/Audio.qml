pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.settings
import qs.services
import qs.components.animations

Item {
    id: root
    
    implicitWidth: layout.implicitWidth
    implicitHeight: Config.barHeight
    
    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 8
        
        // Volume icon button
        Rectangle {
            Layout.preferredWidth: Config.barHeight
            Layout.preferredHeight: Config.barHeight
            radius: root.height / 3
            color: Colors.brighten_5
            
            AnimatedColor on color {}
            
            Text {
                anchors.centerIn: parent
                text: Audio.volumeIcon
                font.family: Fonts.iconFont
                font.pixelSize: 20
                color: Audio.muted ? Colors.red : Colors.text
                
                AnimatedColor on color {}
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                
                onClicked: {
                    Audio.toggleMute();
                }
                
                onEntered: {
                    parent.color = Colors.brighten_10;
                }
                
                onExited: {
                    parent.color = Colors.brighten_5;
                }
            }
        }
        
        // Volume bar container
        ClippingRectangle {
            id: volumeBar
            Layout.preferredWidth: 120
            Layout.preferredHeight: Config.barHeight
            
            radius: root.height / 3
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
            
            // Volume percentage text
            Text {
                anchors.centerIn: parent
                text: Audio.volumePercent + "%"
                color: Colors.text
                font.pixelSize: Fonts.p
                font.bold: true
                
                AnimatedColor on color {}
            }
            
            // Interactive volume control - click and drag to adjust volume
            MouseArea {
                anchors.fill: parent
                enabled: !Audio.muted
                hoverEnabled: !Audio.muted
                cursorShape: Audio.muted ? Qt.ArrowCursor : Qt.PointingHandCursor
                
                // Debounce volume updates to prevent excessive Audio service calls
                property real lastSetVolume: -1
                
                onPressed: (mouse) => {
                    volumeBar.userInteracting = true;
                    lastSetVolume = -1;
                    updateVolume(mouse.x);
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
