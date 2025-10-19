pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.launcher

/**
 * BaseListView - Reusable base ListView component for launcher lists
 * 
 * Provides common functionality for:
 * - Auto-scrolling to keep current item visible
 * - Empty state display
 * - Consistent spacing and clipping
 * - Connection to logic component for index tracking
 * 
 * Usage:
 *   BaseListView {
 *       logic: myLogic
 *       model: myLogic.filteredItems
 *       emptyMessage: "No items found"
 *       delegate: myDelegateComponent
 *   }
 */
ListView {
    id: listView

    // ===== Required Properties =====
    required property var logic
    
    // ===== Optional Properties =====
    property string emptyMessage: "No items found"
    property string emptySearchMessage: ""

    // ===== ListView Configuration =====
    clip: true
    focus: false
    spacing: LauncherConfig.listSpacing
    boundsBehavior: Flickable.DragAndOvershootBounds

    // ===== Auto-scroll Management =====
    
    /**
     * Auto-scroll when currentIndex changes to keep item visible
     */
    onCurrentIndexChanged: {
        if (currentIndex >= 0 && currentIndex < count) {
            positionViewAtIndex(currentIndex, ListView.Contain);
        }
    }

    /**
     * Watch for logic's currentItemIndex changes
     * This ensures smooth scrolling when using keyboard navigation
     */
    Connections {
        target: listView.logic
        
        function onCurrentItemIndexChanged() {
            if (listView.logic && 
                listView.logic.currentItemIndex >= 0 && 
                listView.logic.currentItemIndex < listView.count) {
                listView.positionViewAtIndex(listView.logic.currentItemIndex, ListView.Contain);
            }
        }
    }

    // ===== Empty State =====
    
    // Empty state only shows when the list is actually empty AND the list is visible
    // Parent components control overall visibility via hasResults
    EmptyListState {
        visible: listView.count === 0 && listView.visible
        message: listView.emptyMessage
        searchMessage: listView.emptySearchMessage
    }
}
