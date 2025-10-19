pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/**
 * LauncherConfig - Centralized configuration for the launcher module
 *
 * Provides centralized management of launcher UI dimensions, search engines,
 * file actions, and system commands. All launcher components reference this
 * singleton for consistent behavior and easy customization.
 *
 * **Key Responsibilities:**
 * - UI layout dimensions (search bar, tabs, list items)
 * - Search engine definitions and icon mapping
 * - File action definitions (Open, Open Folder, Copy Path)
 * - Empty state messages for different launcher tabs
 * - System command configuration (terminal launcher)
 *
 * **Usage:**
 * Components import and reference properties like `LauncherConfig.listItemHeight`
 * Logic modules access methods like `LauncherConfig.getEnabledSearchEngines()`
 */
Singleton {
    id: config

    // ===== UI Configuration =====
    readonly property int searchBarHeight: 64
    readonly property int tabBarHeight: 50
    readonly property int listItemHeight: 60
    readonly property int actionItemHeight: 48
    readonly property int listSpacing: 4

    // ===== Search Engines =====
    /**
     * Get the icon path for a search engine by name
     * Maps logical icon names to file paths within the assets directory
     * @param iconName The logical name of the icon (e.g., "brave", "google")
     * @returns The resolved file path, or empty string if not found
     */
    function getSearchEngineIcon(iconName) {
        const basePath = Qt.resolvedUrl("./assets/");
        const iconMap = {
            "brave": basePath + "brave-browser-icon.png",
            "openai": basePath + "openai-icon.png",
            "youtube": basePath + "youtube-color-icon.png",
            "reddit": basePath + "reddit-icon.png",
            "wikipedia": basePath + "wikipedia-icon.png",
            "google": basePath + "google-color-icon.png"
        };
        return iconMap[iconName] || "";
    }

    /**
     * Configured search engines with metadata and enabled status
     * Each engine requires: name, url template, icon, description, and enabled flag
     */
    readonly property var searchEngines: [
        {
            name: "Brave Search",
            url: "https://search.brave.com/search?q=",
            icon: getSearchEngineIcon("brave"),
            description: "Brave Search - Private Search",
            enabled: true
        },
        {
            name: "ChatGPT",
            url: "https://chat.openai.com/?model=gpt-5&q=",
            icon: getSearchEngineIcon("openai"),
            description: "ChatGPT AI Assistant",
            enabled: true
        },
        {
            name: "YouTube",
            url: "https://www.youtube.com/results?search_query=",
            icon: getSearchEngineIcon("youtube"),
            description: "YouTube Videos",
            enabled: true
        },
        {
            name: "Reddit",
            url: "https://www.reddit.com/search/?q=",
            icon: getSearchEngineIcon("reddit"),
            description: "Reddit Posts Search",
            enabled: true
        },
        {
            name: "Wikipedia",
            url: "https://en.wikipedia.org/w/index.php?search=",
            icon: getSearchEngineIcon("wikipedia"),
            description: "Wikipedia Articles",
            enabled: true
        },
        {
            name: "Google",
            url: "https://www.google.com/search?q=",
            icon: getSearchEngineIcon("google"),
            description: "Google Search",
            enabled: true
        }
    ]

    /**
     * Get all currently enabled search engines
     * @returns Array of enabled search engine objects
     */
    function getEnabledSearchEngines() {
        return config.searchEngines.filter(engine => engine.enabled);
    }

    // ===== File Actions =====
    /**
     * Standard file action definitions used in file search results
     * Each action has a display name and associated icon identifier
     */
    readonly property var fileActionDefinitions: [
        {
            name: "Open",
            icon: "folder-open"
        },
        {
            name: "Open Folder",
            icon: "folder"
        },
        {
            name: "Copy Path",
            icon: "content-copy"
        }
    ]

    // ===== Empty State Messages =====
    /**
     * User-facing messages for empty states in different launcher views
     * Each tab provides contextual messages for empty and search scenarios
     */
    readonly property var emptyStateMessages: {
        "apps": {
            "empty": "No applications found",
            "search": "No applications match your search"
        },
        "files": {
            "empty": "Directory is empty",
            "search": "No files found"
        },
        "websearch": {
            "empty": "No search engines configured",
            "search": "Type to search..."
        }
    }

    // ===== Terminal Settings =====
    /**
     * System terminal command and arguments for executing applications
     * Used when launching applications with terminal requirement
     */
    readonly property string terminalCommand: "kitty"
    readonly property var terminalArgs: ["sh", "-c"]
}
