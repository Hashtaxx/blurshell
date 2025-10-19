pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root
    width: parent.width

    // Allow customization
    property real lineWidth: 0.8    
    height: 16
    
    Rectangle {
        id: separator
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * lineWidth
        height: 1
        color: "transparent"
        radius: 0.5
    }
}
