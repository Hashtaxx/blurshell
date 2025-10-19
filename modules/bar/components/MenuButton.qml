pragma ComponentBehavior: Bound
import QtQuick
import qs.settings
import qs.components.animations

MouseArea {
    id: root
    
    implicitWidth: parent ? parent.height * 2.5 : 80
    implicitHeight: parent ? parent.height : 32
    
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    property bool isActive: false
    property string icon: Fonts.iconCircle
    property color activeColor: Colors.text
    property color inactiveColor: Colors.bgBlur

    Background {
        anchors.fill: parent
        chipColor: root.isActive ? root.activeColor : root.inactiveColor
        border.width: 1
        border.color: parent.containsMouse ? root.activeColor : this.chipColor
        
        AnimatedColor on border.color {}

        Text {
            anchors.centerIn: parent
            color: root.isActive ? root.inactiveColor : root.activeColor
            font.pixelSize: parent.height * 0.9
            text: root.icon
        }
    }
}
