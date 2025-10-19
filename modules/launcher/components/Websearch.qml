pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.launcher
import qs.modules.launcher.functions

Item {
    id: root

    // Properties passed from parent
    property alias searchText: searchLogic.searchText
    
    // Signals
    signal appExecuted  // Using same signal name for consistency with launcher

    // Logic
    WebsearchLogic {
        id: searchLogic
        
        onModelRebuilt: {
            searchList.currentIndex = searchLogic.currentItemIndex;
        }

        // Forward itemExecuted signal
        onItemExecuted: {
            root.appExecuted();
        }
    }

    // ListView
    WebsearchList {
        id: searchList
        anchors.fill: parent
        logic: searchLogic
        model: searchLogic.filteredSearchEngines
        currentIndex: searchLogic.currentItemIndex
        emptyMessage: LauncherConfig.emptyStateMessages.websearch.empty
        emptySearchMessage: root.searchText.length > 0 ? `Search: "${root.searchText}"` : LauncherConfig.emptyStateMessages.websearch.search
    }

    // Public API for parent (Launcher.qml)
    function navigateDown() {
        searchLogic.navigateDown();
    }

    function navigateUp() {
        searchLogic.navigateUp();
    }

    function executeSelected() {
        searchLogic.executeSelected();
    }

    function expandSelected() {
        // No expansion needed for websearch
    }

    function resetState() {
        searchLogic.resetState();
    }

    // Called when this tab becomes active
    function onTabActivated() {
        // Websearch doesn't need special handling on tab activation
    }

    // React to search changes
    onSearchTextChanged: {
        searchLogic.onSearchChanged();
    }
}
