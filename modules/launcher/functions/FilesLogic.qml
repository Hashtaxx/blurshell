/**
 * FilesLogic - File search and action management for launcher
 * 
 * Manages file search results and provides standard file operations
 * (open, open containing folder, copy path) for selected files.
 * 
 * Integrates with FileSearch service to handle real-time search updates
 * and delegates file operations to system handlers.
 * 
 * File actions are defined in LauncherConfig and mapped to FileSearch
 * service methods for consistent behavior across the launcher.
 */

pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.launcher

BaseListLogic {
    id: logic

    // ===== File-Specific Properties =====
    property var filteredFiles: []
    property bool hasResults: false  // Exposed to frontend to track if search completed
    property bool initialized: false  // Track if component has been initialized
    property bool searchTriggered: false  // Track if we've triggered our own search (to ignore cached results)

    // ===== File Actions (built from Config) =====
    readonly property var fileActions: {
        const actions = [];
        const actionDefs = LauncherConfig.fileActionDefinitions;
        
        for (let i = 0; i < actionDefs.length; i++) {
            const def = actionDefs[i];
            
            if (def.name === "Open") {
                actions.push({
                    name: def.name,
                    icon: def.icon,
                    action: function(file) {
                        FileSearch.openFile(file.path);
                        logic.itemExecuted();
                    }
                });
            } else if (def.name === "Open Folder") {
                actions.push({
                    name: def.name,
                    icon: def.icon,
                    action: function(file) {
                        FileSearch.openContainingFolder(file.path);
                        logic.itemExecuted();
                    }
                });
            } else if (def.name === "Copy Path") {
                actions.push({
                    name: def.name,
                    icon: def.icon,
                    action: function(file) {
                        FileSearch.copyToClipboard(file.path);
                    }
                });
            }
        }
        
        return actions;
    }

    // ===== Override Base Methods =====
    
    function getItems() {
        return logic.filteredFiles;
    }

    function getItemActions(item) {
        return logic.fileActions;
    }

    function getItemKey(item) {
        return item.path;
    }

    function executeItem(item) {
        logic.executeFile(item);
    }

    function executeItemAction(action, item) {
        if (action && item) {
            action.action(item);
        }
    }

    // ===== File-Specific Functions =====

    /**
     * Open a file using the system default handler (file manager or associated application).
     * Emits itemExecuted signal to trigger launcher state update.
     */
    function executeFile(file) {
        FileSearch.openFile(file.path);
        logic.itemExecuted();
    }

    // ===== Monitor FileSearch Results =====
    
    property var _fileSearchResults: FileSearch.searchResults
    on_FileSearchResultsChanged: {
        // Only accept results if we've triggered our own search (ignore cached results from before initialization)
        if (!logic.searchTriggered) {
            return;
        }
        
        logic.filteredFiles = FileSearch.searchResults;
        logic.validateIndices();
        logic.modelRebuilt();
    }

    property bool _fileSearchHasPerformed: FileSearch.hasPerformedSearch
    on_FileSearchHasPerformedChanged: {
        // Only accept search status if we've triggered our own search
        if (!logic.searchTriggered) {
            return;
        }
        
        logic.hasResults = FileSearch.hasPerformedSearch;
    }

    /**
     * Handle search text changes by triggering a new file search.
     * Resets navigation state and triggers FileSearch service with new query.
     */
    function onSearchChanged() {
        // Only search if component is initialized
        if (!logic.initialized) {
            return;
        }
        
        logic.currentItemIndex = 0;
        logic.currentActionIndex = -1;
        logic.expandedItems = {};

        logic.searchTriggered = true;  // Mark that we've triggered a search
        FileSearch.search(logic.searchText);
    }

    /**
     * Override resetState to clear files and search when resetting the model.
     */
    function resetState() {
        logic.currentItemIndex = 0;
        logic.currentActionIndex = -1;
        logic.expandedItems = {};
        logic.filteredFiles = [];
        logic.hasResults = false;
        logic.searchTriggered = false;  // Reset search trigger flag
    }

    // ===== Initialization =====
    Component.onCompleted: {
        logic.initialized = true;
        logic.searchTriggered = true;  // Mark that we're triggering a search
        FileSearch.search(logic.searchText);
    }
}
