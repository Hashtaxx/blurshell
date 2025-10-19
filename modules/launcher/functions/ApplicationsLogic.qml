/**
 * ApplicationsLogic - Application launcher business logic
 * 
 * Manages desktop application discovery, filtering, and execution.
 * 
 * Key responsibilities:
 * - Discover and cache applications from DesktopEntries
 * - Filter applications based on search text by name, generic name, or comment
 * - Sort results intelligently: by usage when searching, alphabetically when idle
 * - Execute applications directly or within a terminal environment
 * - Track application usage for frequency-based sorting
 * - Maintain keyboard navigation state through BaseListLogic
 * 
 * The filtering combines all app metadata fields and applies smart sorting
 * to ensure frequently-used applications appear first during searches, while
 * maintaining alphabetical order for browsing without search terms.
 */

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.launcher

BaseListLogic {
    id: logic

    // ===== App-Specific Properties =====
    property var allApps: []
    property var filteredApps: []
    property var usageData: ({})
    property var usageTracker: null

    // ===== Signals =====
    signal appsChanged

    // ===== Override Base Methods =====

    function getItems() {
        return logic.filteredApps;
    }

    function getItemActions(item) {
        return item.actions || [];
    }

    function getItemKey(item) {
        return item.name;
    }

    function executeItem(item) {
        logic.executeApp(item);
    }

    function executeItemAction(action, item) {
        logic.executeAction(action);
    }

    // ===== App-Specific Functions =====

    /**
     * Increments usage tracking for an application to enable frequency-based sorting
     * in subsequent searches. Only executes if both appName and usageTracker are available.
     */
    function incrementUsage(appName) {
        if (!appName || !usageTracker)
            return;

        usageTracker.incrementUsage(appName);
    }

    /**
     * Executes an application, launching it either directly or within a terminal
     * based on its runInTerminal property. Automatically updates usage tracking and
     * emits the itemExecuted signal for UI state management.
     */
    function executeApp(app) {
        if (!app)
            return;

        if (!app.runInTerminal) {
            app.execute();
        } else {
            const cmd = [LauncherConfig.terminalCommand].concat(LauncherConfig.terminalArgs).concat([app.execString]);
            Quickshell.execDetached({
                command: cmd,
                workingDirectory: app.workingDirectory
            });
        }

        logic.incrementUsage(app.name);
        logic.itemExecuted();
    }

    /**
     * Executes an action associated with an application item and notifies
     * the UI that an action was executed.
     */
    function executeAction(action) {
        if (!action)
            return;

        action.execute();
        logic.itemExecuted();
    }

    /**
     * Checks if an application matches the provided search text by comparing against
     * its name, generic name, and comment fields in a case-insensitive manner.
     * Returns true if searchLower is empty (show all apps) or if any field matches.
     */
    function matchesApp(app, searchLower) {
        if (!searchLower)
            return true;
        return (app.name || "").toLowerCase().includes(searchLower) || (app.genericName || "").toLowerCase().includes(searchLower) || (app.comment || "").toLowerCase().includes(searchLower);
    }

    /**
     * Sorts applications using smart heuristics:
     * - Without search text: alphabetical order for comfortable browsing
     * - With search text: by usage count (descending), then alphabetically
     * This prioritizes frequently-used applications when searching while maintaining
     * alphabetical discovery when browsing the full list.
     */
    function sortApps(apps, searchLower, usage) {
        if (!searchLower) {
            return apps.slice().sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        }

        return apps.slice().sort((a, b) => {
            const ua = usage[a.name] || 0;
            const ub = usage[b.name] || 0;
            if (ua !== ub)
                return ub - ua;
            return (a.name || "").localeCompare(b.name || "");
        });
    }

    /**
     * Initializes the application list by fetching all available desktop entries
     * and storing them. Applications are pre-sorted alphabetically for initial display.
     */
    function buildAllApps() {
        let apps = [...DesktopEntries.applications.values].sort((a, b) => a.name.localeCompare(b.name));

        logic.allApps = apps.map(app => Object.assign({}, app));

        logic.rebuildFilteredApps();
        logic.appsChanged();
    }

    /**
     * Rebuilds the filtered application list based on current search text.
     * Applies filtering via matchesApp() and sorting via sortApps(), then
     * validates navigation indices and emits modelRebuilt signal for the UI.
     */
    function rebuildFilteredApps() {
        const usage = logic.usageData || {};
        const lowered = logic.searchText.toLowerCase().trim();

        const visibleApps = logic.allApps.filter(app => matchesApp(app, lowered));
        logic.filteredApps = sortApps(visibleApps, lowered, usage);

        logic.validateIndices();
        logic.modelRebuilt();
    }

    /**
     * Handles search text changes by resetting navigation state and rebuilding
     * the filtered application list. Clears action selection and item expansions
     * to reset the UI to a clean state when the user begins a new search.
     */
    function onSearchChanged() {
        logic.currentItemIndex = 0;
        logic.currentActionIndex = -1;
        logic.expandedItems = {};

        logic.rebuildFilteredApps();
    }

    // ===== Initialization =====
    Component.onCompleted: {
        buildAllApps();

        // Subscribe to real-time changes in available desktop entries (Quickshell 2.1+)
        DesktopEntries.applicationsChanged.connect(function () {
            if (logic) {
                logic.buildAllApps();
            }
        });
    }
}
