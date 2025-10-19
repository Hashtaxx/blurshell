pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.settings
import qs.services
import qs.components
import qs.components.animations
import qs.components.notifications
import "../../../components/notifications/notification_utils.js" as NotificationUtils

/**
 * Sub-notification item component for grouped notifications
 * Displays as a single line when collapsed, full content when expanded
 */
Rectangle {
    id: root
    
    property var notificationObject
    property bool expanded: false
    property real padding: 8
    
    implicitHeight: (root.expanded ? expandedContent.implicitHeight : collapsedLayout.implicitHeight) + padding * 2
    width: parent.width
    radius: 8
    color: root.expanded ? Colors.brighten_10 : Colors.brighten_5
    
    AnimatedColor on color {}
    
    Behavior on implicitHeight {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    
    // Collapsed state: Single line with "summary • body" and dismiss button
    RowLayout {
        id: collapsedLayout
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 8
        visible: !root.expanded
        
        Text {
            Layout.fillWidth: true
            text: {
                const summary = root.notificationObject?.summary || ""
                const body = root.notificationObject?.body || ""
                const appName = root.notificationObject?.appName || root.notificationObject?.summary || ""
                const processedBody = NotificationUtils.processNotificationBody(body, appName)
                
                // Combine summary and body with bullet separator
                if (processedBody) {
                    return summary + " • " + processedBody
                }
                return summary
            }
            font.pixelSize: Fonts.h6
            color: Colors.text
            elide: Text.ElideRight
            maximumLineCount: 1
            textFormat: Text.StyledText
        }
        
        // Dismiss button for collapsed state
        ActionButton {
            id: collapsedDismissButton
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            backgroundColor: Colors.red
            borderColor: Colors.red
            textColor: collapsedDismissButton.containsMouse ? Colors.text : Colors.red
            icon: Fonts.iconFalse
            iconSize: 0.5
            
            onClicked: {
                Notifications.discardNotification(root.notificationObject?.notificationId ?? 0)
            }
        }
    }
    
    // Expanded state: Full notification content with integrated dismiss button
    NotificationContent {
        id: expandedContent
        anchors.fill: parent
        anchors.margins: root.padding
        visible: root.expanded
        
        notificationObject: root.notificationObject
        isGroup: false
        showTimestamp: false
        showDismissButton: true
        titleFontSize: Fonts.p
        bodyFontSize: Fonts.h6
        titleFontWeight: Font.DemiBold
        titleColor: Colors.text
        bodyColor: Colors.textSubdued
        maxBodyLines: -1  // Show full content when expanded
        
        onDismissRequested: {
            Notifications.discardNotification(root.notificationObject?.notificationId ?? 0)
        }
    }
    
    // Click to expand/collapse or execute default action
    MouseArea {
        anchors.fill: parent
        z: -1
        cursorShape: {
            // Check if default action exists
            const actions = root.notificationObject?.actions || []
            const hasDefaultAction = actions.some(action => action.identifier === "default")
            
            if (!root.expanded) {
                // Collapsed: always show pointer to expand
                return Qt.PointingHandCursor
            } else if (hasDefaultAction) {
                // Expanded with default action: show pointer
                return Qt.PointingHandCursor
            }
            // No default action available
            return Qt.ArrowCursor
        }
        
        onClicked: (mouse) => {
            if (!root.expanded) {
                // Collapsed: expand it
                root.expanded = true
            } else if (root.notificationObject) {
                // Expanded: execute default action if available
                const actions = root.notificationObject?.actions || []
                const defaultAction = actions.find(action => action.identifier === "default")
                if (defaultAction) {
                    Notifications.attemptInvokeAction(
                        root.notificationObject.notificationId,
                        "default"
                    )
                }
            }
        }
    }
}
