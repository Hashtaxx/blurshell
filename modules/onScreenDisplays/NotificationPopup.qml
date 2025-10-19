/**
 * NotificationPopup.qml
 * 
 * Manages a vertically-stacked notification popup display on-screen.
 * 
 * **Responsibilities:**
 * - Renders notification popups as individual PanelWindows layered on the Overlay
 * - Tracks notification heights for accurate positioning calculations
 * - Auto-cleans up height entries when notifications are dismissed
 * - Notifies focus manager when the last popup closes
 * 
 * **Layout:** Notifications stack vertically from top-right with 10px spacing and margins.
 * **Screen Selection:** Uses Config.mainMonitorId or active screen, falls back to first screen.
 */
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.settings
import qs.services
import qs.modules.onScreenDisplays.components

Scope {
    id: notificationPopup

    // Layout constants
    readonly property int topMargin: 10
    readonly property int rightMargin: 10
    readonly property int notificationSpacing: 10
    readonly property int notificationWidth: 380
    readonly property int panelWindowWidth: 400

    // Track height per notification ID for dynamic positioning
    property var notificationHeights: ({})
    
    /**
     * Calculates cumulative Y-offset for notification at given index.
     * Accounts for all previous notifications' heights plus spacing.
     * Falls back to 100px height estimate if not yet measured.
     */
    function calculateYOffset(notifId, index) {
        let offset = topMargin
        const list = Notifications.popupList
        
        for (let i = 0; i < index; i++) {
            const prevId = list[i].notificationId
            const height = notificationHeights[prevId] ?? 100  // Use nullish coalescing
            offset += height + notificationSpacing
        }
        return offset
    }
    
    /**
     * Records measured height for a notification.
     * Triggers property update to force position recalculation via calculateYOffset.
     */
    function updateNotificationHeight(notifId, height) {
        notificationHeights[notifId] = height
        notificationHeights = notificationHeights  // Force reactivity
    }

    // Automatically clean up height cache when notifications are removed from the popup list
    Connections {
        target: Notifications
        function onPopupListChanged() {
            const currentIds = new Set(Notifications.popupList.map(n => n.notificationId))
            let cleaned = false

            Object.keys(notificationHeights).forEach(id => {
                const numId = parseInt(id)
                if (!currentIds.has(numId)) {
                    delete notificationHeights[id]
                    cleaned = true
                }
            })

            if (cleaned) {
                notificationHeights = notificationHeights  // Force reactivity
                DrawerFocusManager.notifyPopupClosed()
            }
        }
    }

    // Render notification popups as individual windows stacked vertically
    Variants {
        model: Notifications.popupList

        PanelWindow {
            id: notifWindow
            required property var modelData

            // Index of this notification in the current popup list
            readonly property int notifIndex: {
                const list = Notifications.popupList
                return list.findIndex(n => n.notificationId === modelData.notificationId)
            }

            // Resolve target screen (main monitor or active screen, fallback to first)
            readonly property var targetScreen: {
                const s = Quickshell.screens.find(scr => scr.name === Config.mainMonitorId)
                if (s) return s
                const active = Quickshell.screens.find(scr => scr === Quickshell.activeScreen)
                return active ? active : Quickshell.screens[0]
            }

            screen: targetScreen
            visible: true

            WlrLayershell.namespace: "quickshell:notificationPopup:" + modelData.notificationId
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 0

            anchors {
                top: true
                right: true
            }

            margins {
                top: notificationPopup.calculateYOffset(modelData.notificationId, notifIndex)
                right: notificationPopup.rightMargin
            }

            color: "transparent"
            implicitWidth: notificationPopup.panelWindowWidth
            implicitHeight: notifItem.implicitHeight

            NotificationPopupItem {
                id: notifItem
                notificationObject: notifWindow.modelData
                width: notificationPopup.notificationWidth

                onImplicitHeightChanged: {
                    notificationPopup.updateNotificationHeight(
                        notifWindow.modelData.notificationId,
                        implicitHeight
                    )
                }

                Component.onCompleted: {
                    notificationPopup.updateNotificationHeight(
                        notifWindow.modelData.notificationId,
                        implicitHeight
                    )
                }
            }
        }
    }
}
