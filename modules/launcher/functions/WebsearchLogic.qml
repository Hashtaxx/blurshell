/**
 * WebsearchLogic - Web search engine selection and URL opening
 * 
 * Manages a list of configured web search engines and handles opening
 * search queries in the user's default browser. Integration with external
 * search providers is configured via LauncherConfig.
 * 
 * Unlike file/app searches, this always displays all configured search
 * engines regardless of search text, allowing quick access to any engine.
 * Search text is passed as a query parameter to the selected engine.
 */

pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.modules.launcher

BaseListLogic {
    id: logic

    // ===== Websearch-Specific Properties =====
    property var allSearchEngines: []
    property var filteredSearchEngines: []

    // ===== Override Base Methods =====
    
    function getItems() {
        return logic.filteredSearchEngines;
    }

    function getItemActions(item) {
        return [];  // No actions for search engines
    }

    function getItemKey(item) {
        return item.name;
    }

    function executeItem(item) {
        logic.executeSearch(item, logic.searchText.trim());
    }

    function executeItemAction(action, item) {
        // No actions for search engines
    }

    // ===== Websearch-Specific Functions =====

    /**
     * Build the complete search engines list from LauncherConfig
     * 
     * Retrieves all enabled search engines and populates the allSearchEngines
     * list. Called once at initialization and whenever engine configuration
     * changes. Automatically rebuilds the filtered list.
     */
    function buildSearchEngines() {
        logic.allSearchEngines = [];
        
        const engines = LauncherConfig.getEnabledSearchEngines();
        for (let i = 0; i < engines.length; i++) {
            const engine = engines[i];
            logic.allSearchEngines.push({
                name: engine.name,
                url: engine.url,
                icon: engine.icon,
                description: engine.description,
                actions: []
            });
        }

        logic.rebuildFilteredEngines();
    }

    /**
     * Rebuild the filtered engines list for display
     * 
     * Unlike file/app searches, always shows all configured search engines
     * regardless of search text. Search text is used only in the query parameter.
     * Validates selection indices and emits modelRebuilt signal.
     */
    function rebuildFilteredEngines() {
        // Always show all search engines regardless of search text
        logic.filteredSearchEngines = logic.allSearchEngines.slice();

        // Validate indices
        logic.validateIndices();

        logic.modelRebuilt();
    }

    /**
     * Execute search by opening URL in default browser
     * 
     * Takes the selected search engine, URL-encodes the query text, constructs
     * the full search URL, and opens it via xdg-open. Emits itemExecuted signal
     * to close the launcher after execution.
     * 
     * @param engine {Object} The search engine object with url property
     * @param query {string} The search query text to encode
     */
    function executeSearch(engine, query) {
        if (!engine || !query) {
            console.warn("WebsearchLogic: Cannot execute search - missing engine or query");
            return;
        }

        // URL encode the query
        const encodedQuery = encodeURIComponent(query);
        const fullUrl = engine.url + encodedQuery;

        // Open URL in default browser using xdg-open
        Quickshell.execDetached({
            command: ["xdg-open", fullUrl]
        });

        logic.itemExecuted();  // Emit signal
    }

    /**
     * Handle search text changes
     * 
     * Rebuilds the filtered engines list. Unlike file searches, all engines
     * remain visible regardless of search text - the text is only used when
     * constructing the query parameter for the selected engine.
     */
    function onSearchChanged() {
        // Rebuild to trigger any necessary updates
        logic.rebuildFilteredEngines();
    }

    // ===== Initialization =====
    Component.onCompleted: {
        buildSearchEngines();
    }
}
