pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.settings

Item {
    id: root
    
    property alias from: slider.from
    property alias to: slider.to
    property alias value: slider.value
    property alias stepSize: slider.stepSize
    property int sliderWidth: 180
    property int valueTextWidth: 40
    
    signal sliderValueChanged(real value)
    
    implicitWidth: sliderWidth + valueTextWidth + 10
    implicitHeight: slider.implicitHeight
    
    Slider {
        id: slider
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.sliderWidth
        from: 0
        to: 100
        value: 50
        stepSize: 1
        
        onPressedChanged: {
            if (!pressed) {
                // Only emit signal when mouse is released
                root.sliderValueChanged(slider.value)
            }
        }
        
        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: root.sliderWidth
            implicitHeight: 4
            width: slider.availableWidth
            height: implicitHeight
            radius: 2
            color: Colors.brighten_10
            
            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                color: Colors.lavender
                radius: 2
            }
        }
        
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: 20
            implicitHeight: 20
            radius: 10
            color: slider.pressed ? Colors.lavender : Colors.bg
            border.color: Colors.lavender
            border.width: 2
        }
    }
    
    Text {
        id: valueText
        anchors.left: slider.right
        anchors.leftMargin: 10
        anchors.verticalCenter: slider.verticalCenter
        width: root.valueTextWidth
        text: slider.value.toFixed(2)
        color: Colors.text
        horizontalAlignment: Text.AlignRight
        font.pixelSize: 14
    }
}
