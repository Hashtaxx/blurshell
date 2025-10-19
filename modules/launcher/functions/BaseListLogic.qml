pragma ComponentBehavior: Bound

import QtQuick

/**
 * BaseListLogic - Abstract base for launcher list navigation and state management
 * 
 * Provides unified keyboard/mouse interaction handling for browsing lists with
 * optional per-item actions. Manages selection state, navigation flow, and
 * expansion/collapse of items with associated action menus.
 * 
 * **Navigation Model:**
 * - Items can be selected via keyboard (up/down) or mouse hover
 * - Actions are only visible when parent item is expanded
 * - Down navigation: item → first action (if expanded) → next item
 * - Up navigation: previous item's last action (if expanded) → item
 * - Keyboard navigation disables mouse hover to prevent conflicts
 * 
 * **Subclass Requirements - Must Override:**
 * - getItems(): Return the filtered/sorted list to display
 * - getItemActions(item): Return action array for the item (or empty array)
 * - getItemKey(item): Return unique identifier for expansion tracking
 * - executeItem(item): Handle main item execution
 * - executeItemAction(action, item): Handle action execution
 */
QtObject {
    id: base

    // ===== State Properties =====
    property int currentItemIndex: 0
    property int currentActionIndex: -1
    property var expandedItems: ({})
    property bool keyboardNavigationActive: false
    property bool mouseHoverEnabled: true

    // External references (set by subclass)
    property string searchText: ""

    // ===== Signals =====
    signal modelRebuilt
    signal itemExecuted

    // ===== Timer for hover re-enable =====
    property Timer hoverEnableTimer: Timer {
        interval: 100
        repeat: false
        onTriggered: base.mouseHoverEnabled = true
    }

    // ===== Abstract Methods (Override in subclass) =====
    
    /**
     * Returns the filtered list of items to display.
     * Subclasses must override to return the appropriate model data.
     * @returns {Array} - Array of item objects
     */
    function getItems() {
        console.warn("BaseListLogic: getItems() not implemented in subclass");
        return [];
    }

    /**
     * Returns actions available for a specific item.
     * Return empty array if the item has no actions.
     * @param {Object} item - The item to get actions for
     * @returns {Array} - Array of action objects with name, icon, and action properties
     */
    function getItemActions(item) {
        return [];
    }

    /**
     * Returns unique key for an item, used for expansion state tracking.
     * Key must be stable and unique across the item's lifetime.
     * @param {Object} item - The item to get key for
     * @returns {String} - Unique identifier (typically item.name or item.path)
     */
    function getItemKey(item) {
        console.warn("BaseListLogic: getItemKey() not implemented in subclass");
        return "";
    }

    /**
     * Execute the primary action for an item (e.g., launch an app, open a file).
     * Subclass should call itemExecuted() signal when appropriate.
     * @param {Object} item - The item to execute
     */
    function executeItem(item) {
        console.warn("BaseListLogic: executeItem() not implemented in subclass");
    }

    /**
     * Execute a secondary action on an item (e.g., "Open Folder", "Copy Path").
     * Subclass should call itemExecuted() signal when appropriate.
     * @param {Object} action - The action to execute
     * @param {Object} item - The parent item
     */
    function executeItemAction(action, item) {
        console.warn("BaseListLogic: executeItemAction() not implemented in subclass");
    }

    // ===== Selection Management =====

    /**
     * Get currently selected item and action info.
     * Returns the currently focused item or action based on navigation state.
     * @returns {Object|null} - { type: "item"|"action", item: Object, action?: Object } or null if list is empty
     */
    function getCurrentSelection() {
        const items = base.getItems();
        if (items.length === 0 || base.currentItemIndex >= items.length) {
            return null;
        }

        const currentItem = items[base.currentItemIndex];
        const itemKey = base.getItemKey(currentItem);
        const actions = base.getItemActions(currentItem);

        if (base.currentActionIndex >= 0 && 
            base.expandedItems[itemKey] && 
            actions && 
            base.currentActionIndex < actions.length) {
            return {
                type: "action",
                item: currentItem,
                action: actions[base.currentActionIndex]
            };
        }

        return {
            type: "item",
            item: currentItem
        };
    }

    // ===== Expansion Management =====

    /**
     * Toggle expansion state for an item to show/hide its actions.
     * Temporarily disables mouse hover to prevent flickering when expanding.
     * @param {String} itemKey - Unique key for the item
     */
    function toggleExpansion(itemKey) {
        const newExpanded = Object.assign({}, base.expandedItems);
        const wasExpanded = !!base.expandedItems[itemKey];
        newExpanded[itemKey] = !wasExpanded;
        base.expandedItems = newExpanded;

        if (wasExpanded) {
            base.currentActionIndex = -1;
        } else {
            base.mouseHoverEnabled = false;
            hoverEnableTimer.restart();
        }

        base.modelRebuilt();
    }

    // ===== Navigation Functions =====

    /**
     * Navigate down through items and actions.
     * Activates keyboard navigation mode. Navigation flow:
     * item → first action (if expanded) → next item
     */
    function navigateDown() {
        base.keyboardNavigationActive = true;
        
        const items = base.getItems();
        if (items.length === 0) return;

        const currentItem = items[base.currentItemIndex];
        const itemKey = base.getItemKey(currentItem);
        const isExpanded = base.expandedItems[itemKey];
        const actions = base.getItemActions(currentItem);
        const hasActions = actions && actions.length > 0;

        if (base.currentActionIndex >= 0) {
            if (base.currentActionIndex < actions.length - 1) {
                base.currentActionIndex++;
            } else {
                base.currentItemIndex = (base.currentItemIndex + 1) % items.length;
                base.currentActionIndex = -1;
            }
        } else {
            if (isExpanded && hasActions) {
                base.currentActionIndex = 0;
            } else {
                base.currentItemIndex = (base.currentItemIndex + 1) % items.length;
            }
        }
    }

    /**
     * Navigate up through items and actions.
     * Activates keyboard navigation mode. Navigation flow:
     * previous item's last action (if expanded) → item
     */
    function navigateUp() {
        base.keyboardNavigationActive = true;
        
        const items = base.getItems();
        if (items.length === 0) return;

        if (base.currentActionIndex >= 0) {
            if (base.currentActionIndex > 0) {
                base.currentActionIndex--;
            } else {
                base.currentActionIndex = -1;
            }
        } else {
            const prevItemIndex = (base.currentItemIndex - 1 + items.length) % items.length;
            base.currentItemIndex = prevItemIndex;

            const prevItem = items[prevItemIndex];
            const prevItemKey = base.getItemKey(prevItem);
            const isPrevExpanded = base.expandedItems[prevItemKey];
            const prevActions = base.getItemActions(prevItem);
            const prevHasActions = prevActions && prevActions.length > 0;

            if (isPrevExpanded && prevHasActions) {
                base.currentActionIndex = prevActions.length - 1;
            } else {
                base.currentActionIndex = -1;
            }
        }
    }

    /**
     * Execute the currently selected item or action based on navigation state.
     */
    function executeSelected() {
        const selection = base.getCurrentSelection();
        if (!selection) return;

        if (selection.type === "action") {
            base.executeItemAction(selection.action, selection.item);
        } else {
            base.executeItem(selection.item);
        }
    }

    /**
     * Expand/collapse the currently selected item to show/hide its actions.
     */
    function expandSelected() {
        const selection = base.getCurrentSelection();
        if (!selection || selection.type !== "item") return;

        const actions = base.getItemActions(selection.item);
        if (actions && actions.length > 0) {
            const itemKey = base.getItemKey(selection.item);
            base.toggleExpansion(itemKey);
        }
    }

    // ===== Mouse Interaction Helpers =====

    /**
     * Select an item by index via mouse hover.
     * Only works when keyboard navigation is inactive and mouse hover is enabled.
     * @param {Number} itemIndex - Index of the item
     */
    function selectItem(itemIndex) {
        if (base.keyboardNavigationActive || !base.mouseHoverEnabled) return;
        
        const items = base.getItems();
        if (itemIndex >= 0 && itemIndex < items.length) {
            base.currentItemIndex = itemIndex;
            base.currentActionIndex = -1;
        }
    }

    /**
     * Select an action by index via mouse hover.
     * Only works when keyboard navigation is inactive and mouse hover is enabled.
     * @param {Number} itemIndex - Index of the parent item
     * @param {Number} actionIndex - Index of the action
     */
    function selectAction(itemIndex, actionIndex) {
        if (base.keyboardNavigationActive || !base.mouseHoverEnabled) return;
        
        const items = base.getItems();
        if (itemIndex >= 0 && itemIndex < items.length) {
            const item = items[itemIndex];
            const itemKey = base.getItemKey(item);
            const actions = base.getItemActions(item);
            
            if (base.expandedItems[itemKey] && 
                actions && 
                actionIndex >= 0 && 
                actionIndex < actions.length) {
                base.currentItemIndex = itemIndex;
                base.currentActionIndex = actionIndex;
            }
        }
    }

    /**
     * Re-enable mouse selection after keyboard navigation.
     * Called when user moves the mouse to switch from keyboard to mouse control.
     */
    function enableMouseSelection() {
        base.keyboardNavigationActive = false;
        base.mouseHoverEnabled = true;
    }

    // ===== State Reset =====

    /**
     * Reset all navigation and interaction state to defaults.
     * Use when completely clearing the model or resetting the UI.
     */
    function resetState() {
        base.currentItemIndex = 0;
        base.currentActionIndex = -1;
        base.expandedItems = {};
        base.keyboardNavigationActive = false;
        base.mouseHoverEnabled = true;
    }

    /**
     * Reset navigation indices when search text changes.
     * Called by subclass onSearchChanged() to handle model updates.
     */
    function onSearchChanged() {
        base.currentItemIndex = 0;
        base.currentActionIndex = -1;
        base.expandedItems = {};
    }

    /**
     * Validate and fix navigation indices after model changes.
     * Ensures currentItemIndex is within valid range; resets action selection.
     * Call this after filtering/sorting to prevent invalid indices.
     */
    function validateIndices() {
        const items = base.getItems();
        if (base.currentItemIndex >= items.length) {
            base.currentItemIndex = Math.max(0, items.length - 1);
        }
        base.currentActionIndex = -1;
    }
}
