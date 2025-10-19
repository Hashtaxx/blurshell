pragma ComponentBehavior: Bound
import QtQuick
import qs.settings

Rectangle {
    id: root
    
    // Public properties
    property bool isLoading: false
    property alias icon: iconText.text
    
    // Signal
    signal clicked()
    
    width: 40
    height: 40
    radius: 20
    color: mouseArea.containsMouse ? Colors.brighten_20 : "transparent"
    
    Text {
        id: iconText
        anchors.centerIn: parent
        text: Fonts.iconRepeat
        color: Colors.text
        font.pixelSize: 20
        font.family: Fonts.iconFont
        
        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
            running: root.isLoading
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
