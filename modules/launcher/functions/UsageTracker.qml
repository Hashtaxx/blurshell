/**
 * UsageTracker - Application usage frequency tracking
 * 
 * Tracks how many times applications are launched from the launcher,
 * persisting usage data to a JSON file for frequency-based sorting.
 * This enables "most used apps first" sorting in launcher views.
 * 
 * Usage data is stored as a mapping of application names to counts:
 * {data: {usageData: {appName: count, ...}}}
 */

pragma ComponentBehavior: Bound

import Quickshell.Io
import QtQuick

QtObject {
    id: usageTracker

    // Properties
    property string usageFilePath: Qt.resolvedUrl("../../../settings/UsageMetric.json");
    property var usageData: ({})

    // Internal components
    property var usageFile: FileView {
        path: usageTracker.usageFilePath
        watchChanges: true

        onFileChanged: {
            reload();
        }

        onAdapterUpdated: {
            writeAdapter();
        }

        adapter: JsonAdapter {
            id: usageAdapter
            property var data: ({})

            onDataChanged: {
                // Handle the nested structure from JSON file: {data: {usageData: {...}}}
                if (data && data.data && data.data.usageData) {
                    usageTracker.usageData = data.data.usageData;
                } else if (data && data.usageData) {
                    // Fallback for {usageData: {...}} structure
                    usageTracker.usageData = data.usageData;
                } else {
                    usageTracker.usageData = {};
                }
            }
        }
    }

    // ===== Public Functions =====

    /**
     * Increment usage count for an application
     * 
     * Adds 1 to the current usage count for the given application name and
     * persists the updated data to the JSON file. If the app is not yet tracked,
     * starts counting from 1.
     * 
     * @param appName {string} The name/identifier of the application
     */
    function incrementUsage(appName) {
        if (!appName) {
            console.warn("UsageTracker: Cannot increment usage for empty app name");
            return;
        }

        let usage = Object.assign({}, usageTracker.usageData);
        const currentCount = usage[appName] || 0;
        usage[appName] = currentCount + 1;

        // Update the adapter with the proper JSON structure matching the file format
        usageFile.adapter.data = {
            "data": {
                "usageData": usage
            }
        };
    }

    /**
     * Get the usage count for an application
     * 
     * @param appName {string} The name/identifier of the application
     * @returns {number} The usage count, or 0 if not tracked
     */
    function getUsageCount(appName) {
        if (!appName)
            return 0;
        return usageTracker.usageData[appName] || 0;
    }

    /**
     * Reset the usage count for a specific application
     * 
     * Removes the application from the usage tracking data and persists
     * the change to the JSON file.
     * 
     * @param appName {string} The name/identifier of the application
     */
    function resetUsage(appName) {
        if (!appName)
            return;
        let usage = Object.assign({}, usageTracker.usageData);
        delete usage[appName];

        // Update the adapter with the proper JSON structure matching the file format
        usageFile.adapter.data = {
            "data": {
                "usageData": usage
            }
        };
    }

    /**
     * Clear all usage data
     * 
     * Removes all tracked applications from usage data. This is typically
     * used for reset or cleanup operations. The change is persisted immediately.
     */
    function clearAllUsage() {
        // Update the adapter with the proper JSON structure matching the file format
        usageFile.adapter.data = {
            "data": {
                "usageData": {}
            }
        };
    }

    /**
     * Get the most frequently used applications
     * 
     * Returns applications sorted by usage count in descending order
     * (most used first). Useful for frequency-based sorting in launcher views.
     * 
     * @param limit {number} Maximum number of apps to return (default 10)
     * @returns {Array} Array of {name, count} objects sorted by usage
     */
    function getMostUsedApps(limit = 10) {
        const usage = usageTracker.usageData;
        const sorted = Object.entries(usage).sort(([, a], [, b]) => b - a).slice(0, limit);

        return sorted.map(([appName, count]) => ({
                    name: appName,
                    count: count
                }));
    }
}
