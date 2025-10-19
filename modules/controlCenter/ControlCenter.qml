pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.settings
import qs.services
import qs.components
import qs.components.animations
import qs.modules.controlCenter.components

/// Main Control Center module providing system status and quick settings
/// Features:
/// - Quick settings grid with expandable bubbles for detailed controls
/// - Real-time system monitoring (uptime, audio, media, notifications)
/// - Power management buttons (suspend, reboot, shutdown)
/// - Bluetooth device discovery and connection management
/// - Notification center integration
Scope {
    reloadableId: "controlCenterModule"

    Mainscreen {
        Drawer {
            id: controlCenterDrawer

            required property var modelData
            screen: modelData

            // Drawer configuration
            isRightDrawer: true
            drawerWidth: Config.controlCenterWidth !== 0 ? Config.controlCenterWidth : (ScreenGeometry.getGeometry(screen.name).width) * 0.2
            accentColor: Config.controlCenterAccent
            drawerVisible: AppState.controlCenterVisible
            contentSpacing: 28

            onCloseRequested: {
                AppState.closeControlCenter();
            }

            /// Stop Bluetooth discovery when drawer closes to reduce resource usage
            onDrawerVisibleChanged: {
                if (!drawerVisible) {
                    Bluetooth.stopDiscovery();
                }
            }

            /// Header row: displays current time and power control buttons
            RowLayout {
                id: topRow
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignTop

                Clock {
                    id: clock
                    Layout.alignment: Qt.AlignLeft
                }

                Item {
                    Layout.fillWidth: true
                }

                PowerButtonGroup {
                    id: actionButtons
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: implicitWidth
                }
            }

            /// Animated container for quick settings grid and expanded bubble content
            /// Handles smooth transitions between grid and detail views
            Item {
                id: quickSettingsContainer
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.preferredHeight: isExpanded ? quickSettings.expandedHeight : quickSettings.implicitHeight
                Layout.maximumHeight: isExpanded ? (ScreenGeometry.getGeometry(controlCenterDrawer.screen.name).height) * 0.4 : quickSettings.implicitHeight

                property bool isExpanded: false
                property bool animationsReady: false
                property bool hasBeenVisible: false

                AnimatedHeight on Layout.preferredHeight {
                    enabled: quickSettingsContainer.animationsReady
                } 
                AnimatedHeight on Layout.maximumHeight {
                    enabled: quickSettingsContainer.animationsReady
                }

                /// Defer animations until after first drawer visibility to prevent
                /// unnecessary animations on startup
                Connections {
                    target: controlCenterDrawer
                    function onDrawerVisibleChanged() {
                        if (controlCenterDrawer.drawerVisible && !quickSettingsContainer.hasBeenVisible) {
                            quickSettingsContainer.hasBeenVisible = true;
                        } else if (quickSettingsContainer.hasBeenVisible) {
                            quickSettingsContainer.animationsReady = true;
                        }
                    }
                }

                /// Quick settings grid showing toggles and status bubbles
                QuickSettings {
                    id: quickSettings
                    anchors.fill: parent
                    visible: !quickSettingsContainer.isExpanded
                    opacity: quickSettingsContainer.isExpanded ? 0 : 1

                    AnimatedOpacity on opacity {}

                    onExpandedStateChanged: expanded => {
                        quickSettingsContainer.isExpanded = expanded;
                    }
                }

                /// Detailed view for expanded bubble content (audio, WiFi, Bluetooth, etc.)
                Loader {
                    id: expandedContentLoader
                    anchors.fill: parent
                    visible: quickSettingsContainer.isExpanded
                    active: quickSettingsContainer.isExpanded
                    opacity: quickSettingsContainer.isExpanded ? 1 : 0
                    sourceComponent: quickSettings.expandedContentComponent

                    Connections {
                        target: expandedContentLoader.item
                        ignoreUnknownSignals: true

                        function onCloseRequested() {
                            quickSettings.collapseAll();
                        }
                    }

                    AnimatedOpacity on opacity {}
                }
            }

            MediaControls {
                id: mediaControls
            }

            NotificationCenter {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            /// Footer: displays system uptime and settings access button
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.rightMargin: 6
                Layout.leftMargin: 6
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    text: {
                        let parts = [];
                        if (System.uptimeDays > 0) {
                            parts.push(System.uptimeDays + "d");
                        }
                        if (System.uptimeHours > 0 || System.uptimeDays > 0) {
                            parts.push(System.uptimeHours + "h");
                        }
                        parts.push(System.uptimeMinutes + "m");
                        return "Uptime: " + parts.join(" ");
                    }
                    font.pixelSize: Fonts.h6
                    color: Colors.textSubdued
                }

                ActionButton {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    icon: Fonts.iconSettings

                    onClicked: {
                        AppState.closeControlCenter();
                        AppState.openSettingsWindow();
                    }
                }
            }

            /// Overlay background for dismissing expanded bubbles on click
            overlayData: [
                MouseArea {
                    anchors.fill: parent
                    visible: quickSettingsContainer.isExpanded
                    z: -1
                    propagateComposedEvents: false
                    cursorShape: Qt.ArrowCursor

                    onClicked: {
                        quickSettings.collapseAll();
                    }
                }
            ]
        }
    }
}
