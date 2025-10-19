pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.settings
import qs.services
import qs.components.animations

Rectangle {
    id: root
    
    required property bool input
    
    implicitHeight: 60
    radius: 8
    color: Colors.brighten_10
    
    AnimatedColor on color {}
    
    // Scale effect on hover
    scale: mouseArea.containsMouse ? 1.02 : 1.0
    AnimatedScale on scale {}
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        
        // Icon
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.input ? Fonts.iconHeadset : Fonts.iconSpeaker
            font.family: Fonts.iconFont
            font.pixelSize: 28
            color: Colors.text
            
            AnimatedColor on color {}
        }
        
        // Labels
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            Text {
                Layout.fillWidth: true
                text: root.input ? "Input" : "Output"
                color: Colors.text
                font.pixelSize: Fonts.h6
                font.bold: true
                elide: Text.ElideRight
                
                AnimatedColor on color {}
            }
            
            Text {
                Layout.fillWidth: true
                text: (root.input ? Audio.sourceName : Audio.sinkName) || "No Device"
                color: Colors.textSubdued
                font.pixelSize: Fonts.p
                elide: Text.ElideRight
                
                AnimatedColor on color {}
            }
        }
        
        // Chevron icon
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: Fonts.iconChevronRight
            font.family: Fonts.iconFont
            font.pixelSize: 16
            color: Colors.textSubdued
            
            AnimatedColor on color {}
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            root.clicked();
        }
    }
    
    signal clicked()
}
