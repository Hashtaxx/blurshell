pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.launcher
import qs.modules.launcher.functions

/// Container for the applications tab in the launcher.
///
/// Manages application discovery, filtering, and execution through a list view.
/// Coordinates between the application logic layer (ApplicationsLogic) and UI components.
/// Supports keyboard navigation, search filtering, and application usage tracking.
///
/// Public API:
/// - searchText: Current search filter text
/// - navigateDown/Up(): Move selection in list
/// - executeSelected(): Launch the selected application
/// - expandSelected(): Toggle expanded details for selected item
/// - resetState(): Clear filters and selection
/// - onTabActivated(): Lifecycle callback when this tab becomes active
Item {
    id: root

    /// Current search filter text, propagated from parent launcher
    property alias searchText: appLogic.searchText

    /// Emitted when an application has been successfully executed
    signal appExecuted

    // ===== Internal Components =====

    /// Tracks application launch frequency and usage patterns
    UsageTracker {
        id: usageTracker
    }

    /// Core business logic for filtering, sorting, and executing applications
    ApplicationsLogic {
        id: appLogic
        usageTracker: usageTracker
        usageData: usageTracker.usageData

        onModelRebuilt: {
            appList.currentIndex = appLogic.currentItemIndex;
        }

        onItemExecuted: {
            root.appExecuted();
        }
    }

    /// Synchronizes usage data changes with filtered application list
    Connections {
        target: usageTracker

        function onUsageDataChanged() {
            appLogic.usageData = usageTracker.usageData;
            appLogic.rebuildFilteredApps();
        }
    }

    // ===== UI Components =====

    /// Displays the filtered list of applications
    ApplicationsList {
        id: appList
        anchors.fill: parent
        logic: appLogic
        model: appLogic.filteredApps
        currentIndex: appLogic.currentItemIndex
        emptyMessage: root.searchText.length > 0
            ? LauncherConfig.emptyStateMessages.apps.search
            : LauncherConfig.emptyStateMessages.apps.empty
        emptySearchMessage: root.searchText.length ? `Search: "${root.searchText}"` : ""
    }

    // ===== Public API =====

    function navigateDown() {
        appLogic.navigateDown();
    }

    function navigateUp() {
        appLogic.navigateUp();
    }

    function executeSelected() {
        appLogic.executeSelected();
    }

    function expandSelected() {
        appLogic.expandSelected();
    }

    function resetState() {
        appLogic.resetState();
    }

    function onTabActivated() {
        // No special handling needed for applications tab activation
    }

    // ===== Signal Handlers =====

    onSearchTextChanged: {
        appLogic.onSearchChanged();
    }
}
