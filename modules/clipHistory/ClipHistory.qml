pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.settings
import qs.components
import qs.services


Scope {
    // ClipHistory Logic
    ClipHistoryLogic {
        id: clipLogic
        onItemExecuted: AppState.closeClipHist()
    }

    Mainscreen {
        Drawer {
            id: clipHistoryDrawer

            required property var modelData
            screen: modelData

            // Drawer configuration (right-sided like Control Center)
            isRightDrawer: true
            drawerWidth: Config.clipHistWidth !== 0 ? Config.clipHistWidth : (ScreenGeometry.getGeometry(screen.name).width) * 0.2
            accentColor: Config.clipHistAccent
            drawerVisible: AppState.clipHistVisible
            contentSpacing: 20

            // Handle close request from focus grab
            onCloseRequested: {
                AppState.closeClipHist();
            }

            // Handle visibility changes
            onDrawerVisibilityChanged: visible => {
                if (visible) {
                    ClipService.refresh();
                    searchBar.forceActiveFocus();
                    clipLogic.resetState();
                    timeUpdateTimer.running = true;
                } else {
                    timeUpdateTimer.running = false;
                }
            }

            // Timer to periodically update "time ago" text
            Timer {
                id: timeUpdateTimer
                interval: 60000  // Update every minute
                repeat: true
                running: false
                onTriggered: {
                    // Trigger a refresh of the preparedEntries to update timeAgo
                    ClipService.lastRefreshTime = ClipService.lastRefreshTime;
                }
            }

            // Search bar at the top
            Searchbar {
                id: searchBar
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                placeholderText: "Search clipboard history..."
                backgroundColor: Colors.darken_20

                onTextChanged: {
                    clipLogic.searchText = searchBar.text;
                    clipLogic.onSearchChanged();
                }

                onNavigateDown: clipLogic.navigateDown()
                onNavigateUp: clipLogic.navigateUp()
                onExecuteSelected: clipLogic.executeSelected()
                
                onCloseRequested: {
                    AppState.closeClipHist();
                }
            }

            // Header with title and clear all button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Clipboard History"
                    color: Colors.text
                    font.pixelSize: Fonts.h4
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }

                // Clear all button
                ActionButton {
                    id: clearAllButton
                    visible: ClipService.preparedEntries.length > 0
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 12
                    backgroundColor: "transparent"
                    borderColor: Colors.red
                    textColor: Colors.red
                    icon: Fonts.iconClear
                    iconSize: 0.6

                    onClicked: {
                        ClipService.clearAll();
                    }
                }
            }

            // Empty state when no clipboard entries
            Item {
                visible: ClipService.preparedEntries.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf0c5"
                        font.family: Fonts.iconFont
                        font.pixelSize: 48
                        color: Qt.alpha(Colors.text, 0.3)
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No clipboard history"
                        font.pixelSize: 16
                        color: Qt.alpha(Colors.text, 0.5)
                    }
                }
            }

            // Clipboard history list - ListView handles its own scrolling
            ListView {
                id: clipHistList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: 8
                visible: ClipService.preparedEntries.length > 0

                // Bind to filtered model from logic
                model: clipLogic.filteredItems

                // Auto-scroll when currentIndex changes
                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < count) {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }
                }

                // Watch for logic's currentItemIndex changes
                Connections {
                    target: clipLogic
                    
                    function onCurrentItemIndexChanged() {
                        if (clipLogic.currentItemIndex >= 0 && 
                            clipLogic.currentItemIndex < clipHistList.count) {
                            clipHistList.positionViewAtIndex(clipLogic.currentItemIndex, ListView.Contain);
                        }
                    }
                }

                // Delegate for each clipboard item
                delegate: ClipListItem {
                    width: clipHistList.width
                    logic: clipLogic
                    itemIndex: index
                }
            }
        }
    }
}