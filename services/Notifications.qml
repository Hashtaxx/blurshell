// Notifications.qml - Manages system notifications, popups, and notification daemon server
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.settings
import qs.services

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

        property bool popup: false
        readonly property date time: new Date()

        readonly property Timer timer: Timer {
            running: wrapper.popup
            interval: wrapper.notification.expireTimeout > 0 ? wrapper.notification.expireTimeout : Config.defaultExpireTimeout
            onTriggered: {
                if (!wrapper.resident) wrapper.popup = false;
            }
        }

        readonly property Connections retainableConn: Connections {
            target: wrapper.notification.Retainable

            function onDropped() {
                const index = root.list.findIndex(n => n.notificationId === wrapper.notificationId);
                if (index !== -1) {
                    root.list.splice(index, 1);
                    root.triggerListChange();
                }
            }

            function onAboutToDestroy() {
                wrapper.destroy();
            }
        }
    }

    property bool silent: false
    property list<Notif> list: []
    property var popupList: list.filter(notif => notif.popup)
    property bool popupInhibited: silent
    property var latestTimeForApp: ({})
    property int maxPopups: 6

    property var groupsByAppName: groupsForList(root.list)
    property var appNameList: appNameListForGroups(root.groupsByAppName)

    Component {
        id: notifComponent
        Notif {}
    }

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

        onNotification: notification => {
            notification.tracked = true;
            const newNotifObject = notifComponent.createObject(root, {
                "notificationId": notification.id,
                "notification": notification
            });
            root.list = [...root.list, newNotifObject];

            if (!root.popupInhibited && !newNotifObject.isTransient) {
                newNotifObject.popup = true;

                const currentPopups = root.list.filter(n => n.popup);
                if (currentPopups.length > root.maxPopups && currentPopups[0]) {
                    currentPopups[0].popup = false;
                }
            }
        }
    }

    function appNameListForGroups(groups) {
        return Object.keys(groups).sort((a, b) => groups[b].time - groups[a].time);
    }

    function groupsForList(list) {
        const groups = {};
        list.forEach(notif => {
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

    function discardNotification(id) {
        const index = root.list.findIndex(notif => notif.notificationId === id);
        if (index !== -1) {
            const newList = root.list.filter(notif => notif.notificationId !== id);
            root.list = newList;
        }
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex(notif => notif.id === id);
        if (notifServerIndex !== -1) {
            notifServer.trackedNotifications.values[notifServerIndex].dismiss();
        }
    }

    function discardAllNotifications() {
        root.list = [];
        triggerListChange();
        notifServer.trackedNotifications.values.forEach(notif => {
            notif.dismiss();
        });
    }

    function cancelTimeout(id) {
        const index = root.list.findIndex(notif => notif.notificationId === id);
        if (root.list[index]?.timer) root.list[index].timer.stop();
    }

    function timeoutNotification(id) {
        const index = root.list.findIndex(notif => notif.notificationId === id);
        if (root.list[index] && !root.list[index].resident && root.list[index].timer) {
            root.list[index].timer.restart();
        }
    }

    function timeoutAll() {
        root.popupList.forEach(notif => {
            notif.popup = false;
        });
    }

    function attemptInvokeAction(id, notifIdentifier) {
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex(notif => notif.id === id);

        if (notifServerIndex !== -1) {
            const notifServerNotif = notifServer.trackedNotifications.values[notifServerIndex];
            const action = notifServerNotif.actions.find(a => a.identifier === notifIdentifier);
            
            if (action) {
                // Create callback that invokes action and dismisses notification
                const actionCallback = () => {
                    action.invoke();
                    // Don't dismiss resident notifications
                    const notif = root.list.find(n => n.notificationId === id);
                    if (notif && !notif.resident) {
                        root.discardNotification(id);
                    }
                };
                
                // Move window from special workspace and invoke action callback
                WindowMover.moveWindowFromSpecial(notifServerNotif, actionCallback);
                return;
            }
        }

        // Fallback: dismiss non-resident notification if no action found
        const notifIndex = root.list.findIndex(notif => notif.notificationId === id);
        if (notifIndex !== -1 && !root.list[notifIndex].resident) {
            root.discardNotification(id);
        }
    }

    function triggerListChange() {
        root.list = root.list.slice(0);
    }

    onListChanged: {
        root.list.forEach(notif => {
            if (!root.latestTimeForApp[notif.appName] || notif.time > root.latestTimeForApp[notif.appName]) {
                root.latestTimeForApp[notif.appName] = Math.max(root.latestTimeForApp[notif.appName] || 0, notif.time);
            }
        });

        Object.keys(root.latestTimeForApp).forEach(appName => {
            if (!root.list.some(notif => notif.appName === appName)) {
                delete root.latestTimeForApp[appName];
            }
        });
    }
}
