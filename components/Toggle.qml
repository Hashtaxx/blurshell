// Toggle.qml
// Interactive toggle switch with smooth sliding animation and configurable state
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.settings
import qs.components.animations

Item {
    id: root

    property alias checked: toggle.checked
    property color checkedColor: Colors.lavender
    
    signal toggled(bool checked)
    
    implicitWidth: 48
    implicitHeight: 24
    
    Switch {
        id: toggle
        anchors.fill: parent
        padding: 0
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        
        onToggled: root.toggled(toggle.checked)
        
        // Custom styling
        indicator: Rectangle {
            implicitWidth: 48
            implicitHeight: 24
            x: 0
            y: parent.height / 2 - height / 2
            radius: 12
            color: toggle.checked ? root.checkedColor : Colors.brighten_20
            border.color: toggle.checked ? root.checkedColor : Colors.brighten_20
            
            AnimatedColor on color {}
            AnimatedColor on border.color {}
            
            Rectangle {
                x: toggle.checked ? parent.width - width - 2 : 2
                y: 2
                width: 20
                height: 20
                radius: 10
                color: Colors.bg
                
                AnimatedPosition on x {}
            }
        }
    }
}
