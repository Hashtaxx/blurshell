pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.settings
import qs.services
import qs.components.animations

Item {
    id: root

    required property var node

    implicitHeight: 72

    // Track the node
    PwObjectTracker {
        objects: [root.node]
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // App info row
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Application Symbol
            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 8
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: {
                        // Get application name/id for symbol lookup
                        const appName = root.node.properties["application.name"] || "";
                        const appId = root.node.properties["application.id"] || "";
                        const iconName = root.node.properties["application.icon-name"] || "";

                        // Try to find symbol in map
                        // Check application.name first (e.g., "zen", "discord")
                        if (appName && Config.appSymbolMap[appName.toLowerCase()]) {
                            return Config.appSymbolMap[appName.toLowerCase()];
                        }

                        // Check application.id (e.g., "dev.zed.Zed")
                        if (appId && Config.appSymbolMap[appId]) {
                            return Config.appSymbolMap[appId];
                        }

                        // Check icon-name (e.g., "org.gnome.Nautilus")
                        if (iconName && Config.appSymbolMap[iconName]) {
                            return Config.appSymbolMap[iconName];
                        }

                        // Default fallback symbol
                        return Fonts.iconVolumeHigh;
                    }
                    font.family: Fonts.iconFont
                    font.pixelSize: 20
                    color: Colors.text
                }
            }

            // Application name and media info
            Text {
                Layout.fillWidth: true
                text: {
                    const app = root.node.properties["application.name"] ??
                    (root.node.description !== "" ? root.node.description : root.node.name);
                    const media = root.node.properties["media.name"];
                    return media !== undefined ? `${app} • ${media}` : app;
                }
                color: Colors.text
                font.pixelSize: Fonts.p
                elide: Text.ElideRight
            }

            // Volume percentage
            Text {
                Layout.alignment: Qt.AlignVCenter
                text: Math.round((root.node.audio?.volume ?? 0) * 100) + "%"
                color: Colors.textSubdued
                font.pixelSize: Fonts.p
            }
        }

        // Volume Slider - Bubble style
        ClippingRectangle {
            id: volumeBar
            Layout.fillWidth: true
            Layout.preferredHeight: 25

            radius: 10
            color: Colors.brighten_3

            property bool userInteracting: false
            property bool animationsReady: false
            property real lastVolume: root.node.audio?.volume ?? 0

            // Only enable animations after volume actually changes
            Connections {
                target: root.node.audio
                function onVolumeChanged() {
                    if (volumeBar.lastVolume !== (root.node.audio?.volume ?? 0)) {
                        volumeBar.animationsReady = true;
                        volumeBar.lastVolume = root.node.audio?.volume ?? 0;
                    }
                }
            }

            // Meter fill
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * (root.node.audio?.volume ?? 0)
                color: Audio.muted ? Qt.alpha(Config.controlCenterAccent, 0.3) : Config.controlCenterAccent

                AnimatedWidth on width {
                    enabled: !volumeBar.userInteracting && volumeBar.animationsReady
                }

                AnimatedColor on color {}
            }

            MouseArea {
                anchors.fill: parent
                enabled: !(root.node.audio?.muted ?? false)
                hoverEnabled: !(root.node.audio?.muted ?? false)
                cursorShape: (root.node.audio?.muted ?? false) ? Qt.ArrowCursor : Qt.PointingHandCursor

                onPressed: (mouse) => {
                    volumeBar.userInteracting = true;
                    updateVolume(mouse.x);
                }

                onPositionChanged: (mouse) => {
                    if (pressed) {
                        updateVolume(mouse.x);
                    }
                }

                onReleased: {
                    volumeBar.userInteracting = false;
                }

                function updateVolume(x: real): void {
                    if (!root.node.audio) return;
                    const newVolume = Math.max(0, Math.min(1, x / width));
                    root.node.audio.volume = newVolume;
                }
            }
        }
    }
}
