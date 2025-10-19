// IconAndText.qml
// Displays an icon and text label in a horizontal row layout
// Supports customizable colors, fonts, spacing, and layout direction
// Mainly used in SettingsWindow
pragma ComponentBehavior: Bound

import QtQuick
import qs.settings

Item {
    id: root

    property alias labelText: label.text
    property alias iconText: icon.text
    property alias direction: row.layoutDirection

    property color textColor: Colors.text
    property alias iconColor: icon.color
    property int fontSize: Fonts.p
    
    property int spacing: 12
    
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    
    Row {
        id: row
        anchors.fill: parent
        spacing: root.spacing
        layoutDirection: Qt.LeftToRight
        
        Text {
            id: icon
            text: root.iconText
            color: root.textColor
            font.family: Fonts.iconFont
            font.pixelSize: root.fontSize
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            id: label
            text: ""
            color: root.textColor
            font.pixelSize: root.fontSize
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}