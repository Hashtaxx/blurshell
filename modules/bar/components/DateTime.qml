pragma ComponentBehavior: Bound
import QtQuick
import qs.settings
import qs.services

MouseArea {
    id: root
    
    implicitWidth: chip.implicitWidth
    implicitHeight: parent ? parent.height : 32
    hoverEnabled: true
    
    Background {
        id: chip
        anchors.fill: parent
        
        Row {
            id: clockContent
            anchors.centerIn: parent
            spacing: 12
            
            Text {
                text: Time.date
                color: Colors.text
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 16
                font.bold: true
            }
            
            Text {
                text: Fonts.iconClock
                font.family: Fonts.iconFont
                color: Colors.text
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
                font.bold: true
            }
            
            Text {
                text: Time.time
                color: Colors.text
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
                font.bold: true
            }
        }
    }
}
