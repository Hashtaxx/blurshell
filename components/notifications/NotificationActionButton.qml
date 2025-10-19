pragma ComponentBehavior: Bound

import QtQuick
import qs.settings
import qs.services
import qs.components.animations

/**
 * Reusable notification action button component
 */
Rectangle {
    id: root
    
    // Required properties
    required property var action
    required property int notificationId
    
    // Style properties
    property real fontSize: Fonts.h6
    property color backgroundColor: Colors.brighten_5
    property color hoverColor: Colors.brighten_20
    property color textColor: Colors.text
    property real borderWidth: 0
    property color borderColor: "transparent"
    property real buttonRadius: 6
    property real horizontalPadding: 20
    property real verticalPadding: 8
    
    width: actionText.implicitWidth + horizontalPadding
    height: actionText.implicitHeight + verticalPadding
    radius: buttonRadius
    color: actionHover.containsMouse ? hoverColor : backgroundColor
    border.width: borderWidth
    border.color: borderColor
    
    AnimatedColor on color {}
    
    Text {
        id: actionText
        anchors.centerIn: parent
        text: root.action?.text || ""
        font.pixelSize: root.fontSize
        color: root.textColor
    }
    
    MouseArea {
        id: actionHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: (mouse) => {
            mouse.accepted = true
            if (root.action) {
                Notifications.attemptInvokeAction(
                    root.notificationId,
                    root.action.identifier
                )
            }
        }
    }
}
