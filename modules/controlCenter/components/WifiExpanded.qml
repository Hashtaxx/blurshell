pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.settings
import qs.services
import qs.components

/**
 * WifiExpanded: Network connectivity control panel for the control center
 *
 * Provides:
 * - Ethernet connection status display
 * - WiFi toggle with on/off state
 * - Available WiFi networks discovery and connection
 * - Network scanning with visual feedback
 * - Password-protected network authentication flow
 *
 * Real-time synchronization with Network service for live connectivity updates.
 */
ExpandedBubble {
    id: root

    title: "Network"
    showHeader: true
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Ethernet connection status (only visible when connected)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            visible: Network.ethernet
            color: "transparent"
            radius: 8

            RowLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 12

                Text {
                    text: Fonts.iconLanOn
                    color: Colors.text
                    Layout.preferredWidth: 16
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Fonts.h5
                    font.family: Fonts.iconFont
                }

                Text {
                    text: "Ethernet"
                    color: Colors.text
                    font.pixelSize: Fonts.h5
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "Connected " + Fonts.iconTrue
                    color: Colors.green
                    font.pixelSize: Fonts.h5
                }
            }
        }

        // WiFi toggle and status indicator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "transparent"
            radius: 8

            RowLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 12

                Text {
                    text: Network.wifiIcon
                    color: Colors.text
                    Layout.preferredWidth: 16
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Fonts.h5
                    font.family: Fonts.iconFont
                }

                Text {
                    Layout.fillWidth: true
                    text: "WiFi"
                    color: Colors.text
                    font.pixelSize: Fonts.h5
                }

                Toggle {
                    checkedColor: Config.controlCenterAccent
                    checked: Network.wifiEnabled

                    onToggled: (checked) => {
                        Network.enableWifi(checked);
                    }
                }
            }
        }

        // WiFi network discovery and connection panel
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.brighten_3
            radius: 8
            visible: Network.wifiEnabled

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 0

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 200
                    clip: true

                    ListView {
                        id: networksList
                        width: parent.width
                        model: Network.wifiNetworks
                        spacing: 4
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: WifiNetworkItem {
                            required property var modelData
                            required property int index

                            width: networksList.width
                            network: modelData

                            onClicked: {
                                if (!network.active) {
                                    if (network.isSecure && !network.askingPassword) {
                                        // Trigger password input for secured networks
                                        network.askingPassword = true;
                                    } else {
                                        Network.connectToWifiNetwork(network);
                                    }
                                }
                            }
                        }

                        // Rescan control in list footer
                        footer: Item {
                            width: networksList.width
                            height: 48

                            ReloadButton {
                                anchors.centerIn: parent
                                isLoading: Network.wifiScanning
                                onClicked: Network.rescanWifi()
                            }
                        }

                        // Empty state and rescan fallback when no networks detected
                        ColumnLayout {
                            anchors.centerIn: parent
                            visible: networksList.count === 0
                            spacing: 12

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Network.wifiScanning ? "Scanning for networks...\nPlease wait..." : "No networks found"
                                color: Colors.textSubdued
                                font.pixelSize: Fonts.p
                                horizontalAlignment: Text.AlignHCenter
                            }

                            ReloadButton {
                                Layout.alignment: Qt.AlignHCenter
                                visible: networksList.count === 0 && !Network.wifiScanning
                                isLoading: Network.wifiScanning
                                onClicked: Network.rescanWifi()
                            }
                        }
                    }
                }
            }
        }

        // WiFi unavailable fallback state
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.brighten_3
            radius: 8
            visible: !Network.wifiEnabled

            Text {
                anchors.centerIn: parent
                text: "WiFi is disabled"
                color: Colors.textSubdued
                font.pixelSize: Fonts.h5
            }
        }
    }
}
