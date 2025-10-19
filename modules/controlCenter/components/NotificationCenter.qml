pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.settings
import qs.services
import qs.components

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // Title row with dismiss-all button (above background)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Notifications"
                color: Colors.text
                font.pixelSize: Fonts.h4
                font.weight: Font.Medium
                Layout.fillWidth: true
            }

            // Dismiss all button
            ActionButton {
                id: closeButton
                visible: Notifications.list.length > 0
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                backgroundColor: "transparent"
                borderColor: Colors.red
                textColor: Colors.red
                icon: Fonts.iconClear
                iconSize: 0.6

                onClicked: {
                    Notifications.discardAllNotifications();
                }
            }
        }

        // Background with margins
        Rectangle {
            id: background
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: Colors.darken_20

            // Empty state - shown when no notifications
            Item {
                anchors.fill: parent
                visible: Notifications.list.length === 0
                
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Text {
                        text: Fonts.iconAllDone // Material icon: delete_sweep
                        font.family: Fonts.iconFont
                        font.pixelSize: 48
                        color: Qt.alpha(Colors.text, 0.3)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: "All done!"
                        color: Qt.alpha(Colors.text, 0.5)
                        font.pixelSize: Fonts.h3
                        font.weight: Font.Medium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Scrollable notification list - shown when notifications exist
            ScrollView {
                id: scrollView
                anchors.fill: parent
                anchors.margins: 16
                visible: Notifications.list.length > 0

                // Disable horizontal scrolling
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                // Make it scrollable but not draggable (use mouse wheel/touch only)
                contentWidth: availableWidth

                ListView {
                    id: notificationList

                    width: scrollView.availableWidth
                    height: contentHeight
                    interactive: false

                    spacing: 8
                    clip: true

                    model: Notifications.appNameList

                    delegate: NotificationGroup {
                        required property int index
                        required property var modelData
                        width: parent ? parent.width : 0
                        notificationGroup: Notifications.groupsByAppName[modelData]
                    }
                }

            }
        }
    }
}
