pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.settings
import qs.services
import qs.components.animations
import qs.components.notifications

MouseArea {
    id: root
    
    property var notificationGroup
    property var notifications: notificationGroup?.notifications ?? []
    property int notificationCount: notifications.length
    property bool multipleNotifications: notificationCount > 1
    property bool popup: false
    property real padding: 10
    
    implicitHeight: background.implicitHeight
    hoverEnabled: true
    cursorShape: {
        if (root.multipleNotifications) {
            return Qt.ArrowCursor
        }
        // Single notification - show pointer if default action exists
        const actions = root.notifications[0]?.actions || []
        const hasDefaultAction = actions.some(action => action.identifier === "default")
        return hasDefaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    
    onContainsMouseChanged: {
        if (!root.popup) return;
        if (root.containsMouse) {
            root.notifications.forEach(notif => {
                Notifications.cancelTimeout(notif.notificationId);
            });
        } else {
            root.notifications.forEach(notif => {
                Notifications.timeoutNotification(notif.notificationId);
            });
        }
    }
    
    onClicked: (mouse) => {
        if (mouse.button === Qt.LeftButton && !root.multipleNotifications) {
            // Single notification - execute default action
            const actions = root.notifications[0]?.actions || []
            const defaultAction = actions.find(action => action.identifier === "default")
            if (defaultAction) {
                Notifications.attemptInvokeAction(
                    root.notifications[0].notificationId,
                    "default"
                )
            }
        } else if (mouse.button === Qt.RightButton) {
            // Right click dismisses all notifications in group
            root.notifications.forEach((notif) => {
                Notifications.discardNotification(notif.notificationId);
            });
        } else if (mouse.button === Qt.MiddleButton) {
            root.notifications.forEach((notif) => {
                Notifications.discardNotification(notif.notificationId);
            });
        }
    }
    
    Rectangle {
        id: background
        anchors.fill: parent
        color: root.containsMouse ? Colors.brighten_10 : Colors.brighten_5
        radius: 12
        clip: true
        
        AnimatedColor on color {}
        
        implicitHeight: row.implicitHeight + root.padding * 2
        
        Behavior on implicitHeight {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        
        RowLayout {
            id: row
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.padding
            spacing: 12
            
            // App icon (for grouped) or notification image (for single)
            NotificationIcon {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                // Show full image only for single notifications, otherwise just app icon
                image: root.notifications[0]?.image || ""
                appIcon: root.notifications[0]?.appIcon || ""
                showImage: !root.multipleNotifications  // Only show image for single notifications
            }
            
            // Unified notification content (handles both single and group scenarios)
            NotificationContent {
                Layout.fillWidth: true
                
                // Single notification mode
                notificationObject: !root.multipleNotifications ? root.notifications[0] : null
                
                // Group mode
                notificationGroup: root.multipleNotifications ? root.notificationGroup : null
                isGroup: root.multipleNotifications
                
                // Display options
                showTimestamp: true
                showDismissButton: true
                titleFontSize: root.multipleNotifications ? Fonts.h6 : Fonts.p
                bodyFontSize: Fonts.h6
                titleFontWeight: root.multipleNotifications ? Font.Medium : Font.DemiBold
                titleColor: root.multipleNotifications ? Colors.textSubdued : Colors.text
                bodyColor: Colors.textSubdued
                maxBodyLines: 4
                
                onDismissRequested: {
                    if (root.multipleNotifications) {
                        // Dismiss all notifications in group
                        root.notifications.forEach((notif) => {
                            Notifications.discardNotification(notif.notificationId);
                        });
                    } else if (root.notifications[0]) {
                        // Single notification dismiss
                        Notifications.discardNotification(root.notifications[0].notificationId);
                    }
                }
                
                // Sub-notifications component for groups
                subNotificationsComponent: root.multipleNotifications ? subNotificationsList : null
            }
        }
    }
    
    // Sub-notifications list component
    Component {
        id: subNotificationsList
        
        ListView {
            implicitHeight: contentHeight
            width: parent ? parent.width : 0
            spacing: 5
            interactive: false
            
            model: root.notifications.slice().reverse()
            
            delegate: NotificationItem {
                required property int index
                required property var modelData
                notificationObject: modelData
                width: parent ? parent.width : 0
            }
        }
    }
}
