pragma ComponentBehavior: Bound
import QtQuick
import qs.settings
import qs.services

Background {
    id: root
    
    property int maxLength: 60
    property string fallbackText: "Hyprland"
    
    readonly property string currentText: {
        if (!HyprStats.activeToplevel || !HyprStats.activeToplevel.title) {
            return fallbackText;
        }
        const title = HyprStats.activeToplevel.title;
        return title.length > maxLength 
            ? title.substring(0, maxLength) + "..." 
            : title;
    }
    
    Text {
        id: titleText
        anchors.centerIn: parent
        text: root.currentText
        color: Colors.text
        font.pixelSize: 14
    }
}
