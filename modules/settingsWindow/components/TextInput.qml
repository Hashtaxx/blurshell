pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell.Wayland
import qs.settings

Item {
    id: root
    
    property alias text: textField.text
    property alias placeholderText: textField.placeholderText
    property int fieldWidth: 180
    
    signal textEdited(string text)
    
    implicitWidth: Math.min(root.fieldWidth, parent ? parent.width : root.fieldWidth)
    implicitHeight: textField.implicitHeight
    
    TextField {
        id: textField
        width: Math.min(root.fieldWidth, parent ? parent.width : root.fieldWidth)
        height: parent.height
        placeholderText: "Enter text..."
        color: Colors.text
        clip: true
        leftPadding: 8
        rightPadding: 8
        selectByMouse: true
        
        background: Rectangle {
            color: Colors.brighten_10
            radius: 6
            border.color: textField.activeFocus ? Colors.lavender : Colors.brighten_10
            border.width: 1
        }
        
        onTextChanged: root.textEdited(textField.text)
    }
}
