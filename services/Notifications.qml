// Notifications.qml - Manages system notifications, popups, and notification daemon server
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.settings

Singleton {
    id: root

    /**
     * Notification wrapper component that extends the base Notification with lifecycle management.
     * Adds popup state, timing, and automatic expiration handling.
     */
    component Notif: QtObject {
        id: wrapper
        required property int notificationId
        required property Notification notification

        // === PROXY PROPERTIES ===
        // Direct property access from underlying notification object
        readonly property list<NotificationAction> actions: notification.actions
        readonly property string appIcon: notification.appIcon
        readonly property string appName: notification.appName
        readonly property string body: notification.body
        readonly property string image: notification.image
        readonly property string summary: notification.summary
        readonly property string urgency: notification.urgency.toString()
        readonly property bool resident: notification.resident
        readonly property bool isTransient: notification.transient
        readonly property bool hasActionIcons: notification.hasActionIcons

        // === WRAPPER STATE ===
        property bool popup: false  // Controls popup visibility in UI
        readonly property date time: new Date()  // Timestamp for sorting and tracking

        // Handles automatic popup dismissal based on expiration timeout
        readonly property Timer timer: Timer {
            running: wrapper.popup
            interval: wrapper.notification.expireTimeout > 0 ? wrapper.notification.expireTimeout : Config.defaultExpireTimeout
            onTriggered: {
                // Resident notifications persist until manually dismissed
                if (!wrapper.resident) {
                    wrapper.popup = false;
                }
            }
        }

        // Monitors notification lifecycle events from the server
        readonly property Connections retainableConn: Connections {
            target: wrapper.notification.Retainable

            /**
             * Handles server-initiated notification removal.
             * Triggered when notification server drops the notification.
             */
            function onDropped() {
                const index = root.list.findIndex(n => n.notificationId === wrapper.notificationId);
                if (index !== -1) {
                    root.list.splice(index, 1);
                    root.triggerListChange();
                }
            }

            /**
             * Cleans up wrapper object when notification is destroyed.
             * Triggered by Quickshell's Retainable lifecycle.
             */
            function onAboutToDestroy() {
                wrapper.destroy();
            }
        }
    }

    // === STATE PROPERTIES ===
    property bool silent: false  // Global mute for new notifications
    property list<Notif> list: []  // All tracked notifications
    property var popupList: list.filter(notif => notif.popup)  // Currently visible popups
    property bool popupInhibited: silent  // Prevents new popups when true
    property var latestTimeForApp: ({})  // Tracks most recent notification per app for sorting
    property int maxPopups: 6  // Prevents screen clutter by limiting simultaneous popups

    // === GROUPED DATA ===
    // Organizes notifications by application for notification center UI
    property var groupsByAppName: groupsForList(root.list)
    property var appNameList: appNameListForGroups(root.groupsByAppName)

    // Factory component for creating notification wrappers
    Component {
        id: notifComponent
        Notif {}
    }

    /**
     * Notification daemon server - makes Quickshell the system notification handler.
     * Receives notifications from applications via D-Bus (freedesktop.org spec).
     */
    NotificationServer {
        id: notifServer
        actionsSupported: true
        actionIconsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        inlineReplySupported: false
        keepOnReload: false
        persistenceSupported: true

        /**
         * Handles incoming notification from D-Bus.
         * Creates wrapper, adds to list, and shows popup if conditions met.
         * @param notification - Notification object from NotificationServer
         */
        onNotification: notification => {
            notification.tracked = true;
            const newNotifObject = notifComponent.createObject(root, {
                "notificationId": notification.id,
                "notification": notification
            });
            root.list = [...root.list, newNotifObject];

            // Transient notifications bypass popups (e.g., volume/brightness OSD)
            if (!root.popupInhibited && !newNotifObject.isTransient) {
                newNotifObject.popup = true;

                // Dismiss oldest popup when limit exceeded
                const currentPopups = root.list.filter(n => n.popup);
                if (currentPopups.length > root.maxPopups) {
                    const oldestPopup = currentPopups[0];
                    if (oldestPopup) {
                        oldestPopup.popup = false;
                    }
                }
            }
        }
    }

    // === HELPER FUNCTIONS ===

    /**
     * Generates sorted list of app names from grouped notifications.
     * @param groups - Object with app names as keys
     * @returns Array of app names sorted by most recent notification time
     */
    function appNameListForGroups(groups) {
        return Object.keys(groups).sort((a, b) => {
            return groups[b].time - groups[a].time;  // Descending by time
        });
    }

    /**
     * Groups notifications by application name with metadata.
     * @param list - Array of Notif wrapper objects
     * @returns Object mapping app names to {appName, appIcon, notifications[], time}
     */
    function groupsForList(list) {
        const groups = {};
        list.forEach(notif => {
            // Initialize group for new apps
            if (!groups[notif.appName]) {
                groups[notif.appName] = {
                    appName: notif.appName,
                    appIcon: notif.appIcon,
                    notifications: [],
                    time: 0
                };
            }
            groups[notif.appName].notifications.push(notif);
            groups[notif.appName].time = latestTimeForApp[notif.appName] || notif.time;
        });
        return groups;
    }

    /**
     * Removes notification from local list and dismisses on server.
     * @param id - Notification ID to discard
     */
    function discardNotification(id) {
        const index = root.list.findIndex(notif => notif.notificationId === id);
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex(notif => notif.id === id);

        if (index !== -1) {
            // Atomic update triggers property change detection
            const newList = root.list.filter(notif => notif.notificationId !== id);
            root.list = newList;
        }
        if (notifServerIndex !== -1) {
            notifServer.trackedNotifications.values[notifServerIndex].dismiss();
        }
    }

    /**
     * Clears all notifications from list and dismisses them on server.
     */
    function discardAllNotifications() {
        root.list = [];
        triggerListChange();
        notifServer.trackedNotifications.values.forEach(notif => {
            notif.dismiss();
        });
    }

    /**
     * Stops auto-dismissal timer for a notification.
     * @param id - Notification ID to keep visible
     */
    function cancelTimeout(id) {
        const index = root.list.findIndex(notif => notif.notificationId === id);
        if (root.list[index] != null && root.list[index].timer)
            root.list[index].timer.stop();
    }

    /**
     * Restarts expiration timer for a notification (e.g., on hover).
     * @param id - Notification ID to reset timer for
     */
    function timeoutNotification(id) {
        const index = root.list.findIndex(notif => notif.notificationId === id);
        if (root.list[index] != null && !root.list[index].resident && root.list[index].timer) {
            // Extends visibility duration instead of immediate dismissal
            root.list[index].timer.restart();
        }
    }

    /**
     * Dismisses all visible popup notifications.
     */
    function timeoutAll() {
        root.popupList.forEach(notif => {
            notif.popup = false;
        });
    }

    /**
     * Invokes notification action (e.g., "Open", "Reply") and handles post-action cleanup.
     * @param id - Notification ID
     * @param notifIdentifier - Action identifier string from notification
     */
    function attemptInvokeAction(id, notifIdentifier) {
        console.log("[Notifications] Invoking action:", notifIdentifier, "for ID:", id);
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex(notif => notif.id === id);

        if (notifServerIndex !== -1) {
            const notifServerNotif = notifServer.trackedNotifications.values[notifServerIndex];
            const action = notifServerNotif.actions.find(action => action.identifier === notifIdentifier);
            if (action) {
                action.invoke();
            }
        }

        // Resident notifications persist after action invocation
        const notifIndex = root.list.findIndex(notif => notif.notificationId === id);
        if (notifIndex !== -1 && !root.list[notifIndex].resident) {
            root.discardNotification(id);
        }
    }

    /**
     * Forces QML property change detection by creating new array reference.
     * Workaround for in-place array mutations not triggering bindings.
     */
    function triggerListChange() {
        root.list = root.list.slice(0);
    }

    /**
     * Maintains time-based sorting cache for notification groups.
     * Updates when notifications added/removed to keep groups sorted by recency.
     */
    onListChanged: {
        // Update timestamp cache with latest notification per app
        root.list.forEach(notif => {
            if (!root.latestTimeForApp[notif.appName] || notif.time > root.latestTimeForApp[notif.appName]) {
                root.latestTimeForApp[notif.appName] = Math.max(root.latestTimeForApp[notif.appName] || 0, notif.time);
            }
        });

        // Cleanup stale app entries to prevent memory leaks
        Object.keys(root.latestTimeForApp).forEach(appName => {
            if (!root.list.some(notif => notif.appName === appName)) {
                delete root.latestTimeForApp[appName];
            }
        });
    }
}
