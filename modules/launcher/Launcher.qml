pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.settings
import qs.services
import qs.components
import qs.modules.launcher.components

Scope {
    reloadableId: "launcherModule"

    Mainscreen {
        id: launcherVariants

        Drawer {
            id: launcherDrawer

            required property var modelData
            screen: modelData

            // Drawer configuration
            isRightDrawer: false
            drawerWidth: Config.launcherWidth !== 0 ? Config.launcherWidth : (ScreenGeometry.getGeometry(screen.name).width) * 0.25
            accentColor: Config.launcherAccent
            drawerVisible: AppState.launcherVisible

            property int currentTab: 0 // 0: Apps, 1: Files, 2: Web

            // Handle visibility changes
            onDrawerVisibilityChanged: visible => {
                if (visible) {
                    searchBar.forceActiveFocus();
                }
            }

            // Handle close request from focus grab
            onCloseRequested: {
                AppState.closeLauncher();
            }

            // Search bar
            Searchbar {
                id: searchBar
                Layout.fillWidth: true
                Layout.preferredHeight: LauncherConfig.searchBarHeight
                placeholderText: "Search..."

                onTextChanged: {
                    if (contentLoader.item) {
                        contentLoader.item.searchText = searchBar.text;
                    }
                }
                onNavigateDown: {
                    if (contentLoader.item && contentLoader.item.navigateDown) {
                        contentLoader.item.navigateDown();
                    }
                }
                onNavigateUp: {
                    if (contentLoader.item && contentLoader.item.navigateUp) {
                        contentLoader.item.navigateUp();
                    }
                }
                onExecuteSelected: {
                    if (contentLoader.item && contentLoader.item.executeSelected) {
                        contentLoader.item.executeSelected();
                    }
                }
                onNavigateRight: {
                    if (contentLoader.item && contentLoader.item.expandSelected) {
                        contentLoader.item.expandSelected();
                    }
                }
                onTabPressed: {
                    launcherDrawer.currentTab = (launcherDrawer.currentTab + 1) % 3;
                }
                onTabPressedReverse: {
                    launcherDrawer.currentTab = (launcherDrawer.currentTab - 1 + 3) % 3;
                }
            }

            // Tab Navigation
            Tabs {
                id: tabs
                Layout.fillWidth: true
                Layout.preferredHeight: LauncherConfig.tabBarHeight
                currentTab: launcherDrawer.currentTab

                onTabChanged: index => {
                    launcherDrawer.currentTab = index;
                    // Reset state when switching tabs (but keep search text)
                    if (contentLoader.item && contentLoader.item.resetState) {
                        contentLoader.item.resetState();
                    }
                    // Notify the new tab that it's becoming active
                    if (contentLoader.item && contentLoader.item.onTabActivated) {
                        contentLoader.item.onTabActivated();
                    }
                }
            }

            // Content Loader
            Loader {
                id: contentLoader
                Layout.fillWidth: true
                Layout.fillHeight: true

                source: {
                    switch (launcherDrawer.currentTab) {
                    case 0:
                        return "components/Applications.qml";
                    case 1:
                        return "components/Files.qml";
                    case 2:
                        return "components/Websearch.qml";
                    default:
                        return "";
                    }
                }

                onLoaded: {
                    if (item) {
                        // Set the current search text when component loads
                        item.searchText = searchBar.text;

                        // Connect app execution signal to close launcher
                        if (item.appExecuted !== undefined) {
                            item.appExecuted.connect(() => {
                                AppState.closeLauncher();
                            });
                        }

                        // Notify the component it's being activated
                        if (item.onTabActivated) {
                            item.onTabActivated();
                        }
                    }
                }
            }
        }
    }
}
