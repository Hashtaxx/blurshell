pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.settings
import qs.services
import qs.components
import "./notification_utils.js" as NotificationUtils

/**
 * Unified notification content component
 * 
 * Handles all notification display scenarios:
 * - Popup notifications (with timer behind dismiss button)
 * - Single notifications in notification center (with timestamp)
 * - Group headers (with app name, timestamp, and dismiss all)
 * - Sub-notifications (regular display)
 * 
 * Usage:
 * - For popups: Set timerComponent, pass notificationObject
 * - For single notifications: Set showTimestamp=true, showDismissButton=true
 * - For groups: Set isGroup=true, pass notificationGroup, provide subNotificationsComponent
 * - For sub-notifications: Just pass notificationObject with appropriate styling
 */
ColumnLayout {
    id: root
    
    // Required properties (one of these must be set)
    property var notificationObject: null  // For single notifications
    property var notificationGroup: null   // For group headers
    
    // Optional properties for customization
    property bool isGroup: false  // Is this a group header?
    
    // Styling properties
    property int maxBodyLines: 4
    property real titleFontSize: Fonts.p
    property real bodyFontSize: Fonts.h6
    property int titleFontWeight: Font.DemiBold
    property color titleColor: Colors.text
    property color bodyColor: Colors.textSubdued
    
    // Display options
    property bool showTimestamp: false
    property bool showDismissButton: true
    property real dismissButtonSize: 20  // Size of dismiss button (can be overridden)
    
    // Custom components
    property Component timerComponent: null  // Optional timer (for popups) - rendered behind dismiss button
    property Component subNotificationsComponent: null  // Optional sub-notifications list (for groups)
    
    // Custom dismiss handler - called when dismiss button is clicked
    signal dismissRequested()
    
    // Internal dismiss handler
    function handleDismiss() {
        dismissRequested()
    }
    
    // Connect signal to default behavior if no handler is connected
    Component.onCompleted: {
        if (!dismissRequested.hasHandlers) {
            dismissRequested.connect(() => {
                if (notificationObject) {
                    Notifications.discardNotification(notificationObject.notificationId)
                }
            })
        }
    }
    
    // Timer control properties (exposed for popup timer management)
    property alias timerLoader: timerLoader
    
    // Constants
    readonly property real timerButtonScaleFactor: 1.10  // Button is 10% smaller when timer is shown
    
    spacing: 8
    
    // Title row (with optional timestamp and dismiss button)
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        
        // Title/Summary or App name
        Text {
            Layout.fillWidth: true
            text: {
                if (root.isGroup) {
                    return root.notificationGroup?.appName || "Group"
                }
                return root.notificationObject?.summary || "Notification"
            }
            font.pixelSize: root.titleFontSize
            font.weight: root.titleFontWeight
            color: root.titleColor
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        
        // Timestamp
        Text {
            visible: root.showTimestamp
            text: {
                if (!root.showTimestamp) return ""
                const time = root.isGroup 
                    ? (root.notificationGroup?.time ?? Date.now())
                    : (root.notificationObject?.time ?? Date.now())
                return NotificationUtils.getFriendlyNotifTimeString(time)
            }
            font.pixelSize: Fonts.h6
            color: Colors.textSubdued
        }
        
        // Timer + Dismiss button container
        Item {
            Layout.preferredWidth: root.showDismissButton ? root.dismissButtonSize : 0
            Layout.preferredHeight: root.showDismissButton ? root.dismissButtonSize : 0
            visible: root.showDismissButton
            
            // Optional timer component (rendered behind button)
            Loader {
                id: timerLoader
                anchors.centerIn: parent
                // Timer should be slightly larger than button (5% bigger) to show behind it
                width: parent.width
                height: parent.height
                active: root.timerComponent !== null
                sourceComponent: root.timerComponent
                z: 0  // Behind the button
            }
            
            // Dismiss button (always in front)
            ActionButton {
                id: dismissButton
                anchors.centerIn: parent
                width: root.timerComponent !== null ? parent.width / root.timerButtonScaleFactor : parent.width
                height: root.timerComponent !== null ? parent.height / root.timerButtonScaleFactor : parent.height
                z: 1  // In front of timer
                backgroundColor: Colors.red
                borderColor: Colors.red
                textColor: dismissButton.containsMouse ? Colors.text : Colors.red
                icon: Fonts.iconFalse
                iconSize: root.timerComponent !== null ? 0.8 : 0.5
                
                onClicked: {
                    root.handleDismiss()
                }
            }
        }
    }
    
    // Body text
    Text {
        Layout.fillWidth: true
        visible: !root.isGroup && text !== ""
        text: {
            if (root.isGroup || !root.notificationObject) return ""
            
            const body = root.notificationObject.body || ""
            if (!body) return ""
            
            // Process body text (e.g., clean browser notifications)
            const appName = root.notificationObject.appName || root.notificationObject.summary || ""
            const processedBody = NotificationUtils.processNotificationBody(body, appName)
            return processedBody.replace(/\n/g, "<br/>")
        }
        font.pixelSize: root.bodyFontSize
        color: root.bodyColor
        wrapMode: Text.Wrap
        maximumLineCount: root.maxBodyLines
        elide: Text.ElideRight
        textFormat: Text.StyledText
        
        onLinkActivated: (link) => {
            Qt.openUrlExternally(link)
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
        }
    }
    
    // Actions (exclude "default" action as it's triggered by clicking the notification)
    Flow {
        Layout.fillWidth: true
        spacing: 8
        visible: {
            if (root.isGroup || !root.notificationObject) return false
            const actions = root.notificationObject.actions || []
            const nonDefaultActions = actions.filter(action => action.identifier !== "default")
            return nonDefaultActions.length > 0
        }
        
        Repeater {
            model: {
                if (root.isGroup || !root.notificationObject) return []
                const actions = root.notificationObject.actions || []
                return actions.filter(action => action.identifier !== "default")
            }
            
            delegate: NotificationActionButton {
                required property var modelData
                
                action: modelData
                notificationId: root.notificationObject.notificationId
                fontSize: Fonts.h6
                verticalPadding: 12
                horizontalPadding: 20
            }
        }
    }
    
    // Sub-notifications placeholder (for groups)
    Loader {
        Layout.fillWidth: true
        active: root.isGroup && root.subNotificationsComponent !== null
        visible: root.isGroup
        sourceComponent: root.subNotificationsComponent
    }
}
