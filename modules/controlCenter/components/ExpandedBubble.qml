pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.settings
import qs.components

Rectangle {
    id: root
    
    // Content to be placed inside
    default property alias contentData: contentItem.data
    
    // Customizable properties
    property string title: ""
    property bool showHeader: title !== ""
    property color backgroundColor: Colors.darken_20
    property real contentSpacing: 16
    property real maxHeight: 600
    
    // Signal when close button is clicked
    signal closeRequested()
    
    // Use explicit height equal to maxHeight - content will be clipped/scrollable
    height: maxHeight
    
    // Default background styling
    color: backgroundColor
    radius: 12
    
    // MouseArea to consume all clicks and prevent propagation to overlay behind
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        propagateComposedEvents: false
        z: -1  // Behind content but still blocks events
        
        // Allow wheel events for scrolling
        onWheel: (wheel) => { wheel.accepted = false; }
    }
    
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 16
        spacing: root.contentSpacing
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            visible: root.showHeader
            spacing: 12
            
            Text {
                Layout.fillWidth: true
                text: root.title
                color: Colors.text
                font.pixelSize: Fonts.h3
                font.bold: true
            }
            
            // Close button
            ActionButton {
                id: closeButton
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                backgroundColor: Colors.red
                borderColor: Colors.red
                textColor: closeButton.containsMouse ? Colors.text : Colors.red
                icon: Fonts.iconFalse
                iconSize: 2/3
                
                onClicked: {
                    root.closeRequested();
                }
            }
        }
        
        // Content container
        Item {
            id: contentItem
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
