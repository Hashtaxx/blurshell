pragma ComponentBehavior: Bound

import QtQuick
import qs.services

/**
 * ClipHistoryLogic - Logic component for clipboard history navigation
 * 
 * Provides keyboard and mouse navigation for clipboard entries
 */
QtObject {
    id: logic

    // ===== State Properties =====
    property int currentItemIndex: 0
    property bool keyboardNavigationActive: false
    property bool mouseHoverEnabled: true

    // ===== External Properties =====
    property string searchText: ""

    // ===== Computed Properties =====
    readonly property var filteredItems: {
        if (searchText.trim() === "") {
            return ClipService.preparedEntries;
        }
        return ClipService.preparedEntries.filter(entry => 
            entry.text.toLowerCase().includes(searchText.toLowerCase())
        );
    }

    // ===== Signals =====
    signal itemExecuted

    // ===== Navigation Functions =====
    
    /**
     * Navigate down through items (wraps to top when reaching bottom)
     */
    function navigateDown() {
        logic.keyboardNavigationActive = true;
        
        if (logic.filteredItems.length === 0) return;

        // Use modulo to wrap around to the beginning
        logic.currentItemIndex = (logic.currentItemIndex + 1) % logic.filteredItems.length;
    }

    /**
     * Navigate up through items (wraps to bottom when reaching top)
     */
    function navigateUp() {
        logic.keyboardNavigationActive = true;
        
        if (logic.filteredItems.length === 0) return;

        // Add length before modulo to handle negative wrap-around
        logic.currentItemIndex = (logic.currentItemIndex - 1 + logic.filteredItems.length) % logic.filteredItems.length;
    }

    /**
     * Execute the currently selected item
     */
    function executeSelected() {
        if (logic.filteredItems.length === 0 || logic.currentItemIndex >= logic.filteredItems.length) return;

        const currentItem = logic.filteredItems[logic.currentItemIndex];
        ClipService.copyAndPaste(currentItem.entry);
        logic.itemExecuted();
    }

    /**
     * Delete the currently selected item
     */
    function deleteSelected() {
        if (logic.filteredItems.length === 0 || logic.currentItemIndex >= logic.filteredItems.length) return;

        const currentItem = logic.filteredItems[logic.currentItemIndex];
        ClipService.deleteEntry(currentItem.entry);
        
        // Adjust index if needed
        if (logic.currentItemIndex >= logic.filteredItems.length - 1) {
            logic.currentItemIndex = Math.max(0, logic.filteredItems.length - 2);
        }
    }

    // ===== Mouse Interaction Helpers =====

    /**
     * Select an item by index (typically from mouse hover)
     * @param {int} itemIndex - The index of the item to select
     */
    function selectItem(itemIndex) {
        if (logic.keyboardNavigationActive || !logic.mouseHoverEnabled) return;
        
        if (itemIndex >= 0 && itemIndex < logic.filteredItems.length) {
            logic.currentItemIndex = itemIndex;
        }
    }

    /**
     * Re-enable mouse selection (called on mouse movement)
     */
    function enableMouseSelection() {
        logic.keyboardNavigationActive = false;
        logic.mouseHoverEnabled = true;
    }

    // ===== State Reset =====

    /**
     * Reset all state to defaults
     */
    function resetState() {
        logic.currentItemIndex = 0;
        logic.keyboardNavigationActive = false;
        logic.mouseHoverEnabled = true;
    }

    /**
     * Reset indices when search changes
     */
    function onSearchChanged() {
        logic.currentItemIndex = 0;
    }
}
