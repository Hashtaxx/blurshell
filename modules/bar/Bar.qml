pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.settings
import qs.components
import qs.modules.bar.components

Scope {
    id: root
    property color barBackground: "transparent"
    property int margin: Config.gapsIn
    property int radius: Config.barHeight / 3
    Mainscreen {

        PanelWindow {
            id: topbar
            required property var modelData
            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            margins {
                bottom: root.margin
                top: root.margin
                left: Config.gapsOut
                right: Config.gapsOut
            }

            implicitHeight: Config.barHeight
            color: root.barBackground

            Item {
                id: barContainer
                width: parent.width
                height: parent.height
                anchors.fill: parent

                Row {
                    id: leftContent
                    height: parent.height
                    spacing: Config.gapsIn

                    // Start Menu Button
                    MenuButton {
                        height: parent.height
                        icon: Fonts.iconArch
                        isActive: AppState.launcherVisible
                        activeColor: Config.launcherAccent
                        inactiveColor: Config.launcherBackground

                        onClicked: {
                            AppState.toggleLauncher()
                        }

                    }

                    // Window Title Component
                    WindowTitle {
                        height: parent.height
                    }
                }

                Item {
                    id: centerZone
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: centerDateTime.width

                    DateTime {
                        id: centerDateTime
                        height: parent.height
                        anchors.centerIn: parent
                    }
                }

                Item {
                    id: rightZone
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: rightContent.width

                    Row {
                        id: rightContent
                        height: parent.height
                        spacing: Config.gapsIn
                        anchors.right: parent.right

                        // Audio Volume Bar
                        VolumeBar {
                            height: parent.height
                        }

                        // Workspace Indicator
                        WorkspaceIndicator {
                            height: parent.height
                        }

                        // System Tray
                        SystemTray {
                            height: parent.height
                        }

                        // Control Center Button
                        MenuButton {
                            height: parent.height
                            icon: Fonts.iconMenu
                            isActive: AppState.controlCenterVisible ?? false
                            activeColor: Config.controlCenterAccent
                            inactiveColor: Config.controlCenterBackground

                            onClicked: {
                                AppState.toggleControlCenter()
                            }
                        }
                    }
                }
            }
        }
    }
}
