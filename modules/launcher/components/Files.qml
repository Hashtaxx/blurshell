pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.launcher
import qs.modules.launcher.functions

Item {
    id: root

    // Properties passed from parent
    property alias searchText: filesLogic.searchText
    
    // Signals
    signal appExecuted  // Using same signal name for consistency with launcher

    // Logic
    FilesLogic {
        id: filesLogic
        
        onModelRebuilt: {
            filesList.currentIndex = filesLogic.currentItemIndex;
        }

        // Forward itemExecuted signal
        onItemExecuted: {
            root.appExecuted();
        }

        // Show list immediately when results are ready, hide with delay to prevent flashing
        onHasResultsChanged: {
            root.updateVisibility();
        }
        
        onFilteredFilesChanged: {
            root.updateVisibility();
        }
    }
    
    // Function to update visibility based on search results
    function updateVisibility() {
        // Show list when search has been performed (hasResults), regardless of count
        // The FilesList component will show emptyMessage if there are no results
        if (filesLogic.hasResults) {
            // Show immediately when results arrive
            visibilityTimer.stop();
            filesList.visible = true;
        } else {
            // Hide after delay to prevent flashing during quick searches
            visibilityTimer.restart();
        }
    }

    // Debounce timer to prevent flashing when hiding list
    Timer {
        id: visibilityTimer
        interval: 500  // 0.5 second delay
        repeat: false
        onTriggered: {
            if (!filesLogic.hasResults) {
                filesList.visible = false;
            }
        }
    }

    // ListView - visibility controlled by debounced timer
    FilesList {
        id: filesList
        anchors.fill: parent
        logic: filesLogic
        model: filesLogic.filteredFiles
        currentIndex: filesLogic.currentItemIndex
        emptyMessage: root.searchText.length > 0 ? LauncherConfig.emptyStateMessages.files.search : LauncherConfig.emptyStateMessages.files.empty
        emptySearchMessage: root.searchText.length > 0 ? `Search: "${root.searchText}"` : ""
        visible: false  // Initially hidden, controlled by hasResults changes
    }

    // Public API for parent (Launcher.qml)
    function navigateDown() {
        filesLogic.navigateDown();
    }

    function navigateUp() {
        filesLogic.navigateUp();
    }

    function executeSelected() {
        filesLogic.executeSelected();
    }

    function expandSelected() {
        filesLogic.expandSelected();
    }

    function resetState() {
        filesLogic.resetState();
    }

    // React to search changes
    onSearchTextChanged: {
        filesLogic.onSearchChanged();
    }
}
