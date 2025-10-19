pragma ComponentBehavior: Bound

import QtQuick
import qs.settings

// Reusable empty state display for lists
Item {
    id: root
    
    property string message: "No items found"
    property string searchMessage: ""
    
    anchors.fill: parent
    
    Column {
        anchors.centerIn: parent
        spacing: 8
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.message
            color: Colors.textSubdued
            font.pixelSize: Fonts.h4
        }
        
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.searchMessage
            color: Colors.textSubdued
            font.pixelSize: Fonts.p
            visible: text.length > 0
        }
    }
}
