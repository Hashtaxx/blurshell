// WindowActionPopup.qml
// Simple popup with Open/Close buttons for special workspace windows
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.components
import qs.settings
import qs.services

Item {
    id: root
    
    // The window address to act upon
    property string windowAddress: ""
    property string windowTitle: ""
    property string windowClass: ""
    
    // Helper to ensure address has 0x prefix
    readonly property string formattedAddress: {
        if (windowAddress.startsWith("0x")) {
            return windowAddress;
        } else {
            return "0x" + windowAddress;
        }
    }
    
    // The item to anchor the popup to
    property var anchorItem: null
    
    // Read-only property to check visibility
    readonly property bool isVisible: popupWindow.visible
    
    // Signal emitted when an action is taken
    signal actionTaken()
    
    // Function to open the popup
    function open() {
        if (anchorItem && windowAddress) {
            popupWindow.visible = true
            focusGrab.active = true
        } else {
            console.error("WindowActionPopup: Cannot open - missing anchorItem or windowAddress");
        }
    }
    
    // Function to directly focus the window in its current workspace
    function openWindow() {
        if (windowAddress) {
            moveWindowProcess.running = true;
        } else {
            console.error("WindowActionPopup: Cannot open window - missing windowAddress");
        }
    }
    
    // Function to close the popup
    function close() {
        popupWindow.visible = false
        focusGrab.active = false
    }
    
    HyprlandFocusGrab {
        id: focusGrab
        windows: [popupWindow]
        onCleared: {
            popupWindow.visible = false
        }
    }
    
    // Popup window
    Popup {
        id: popupWindow
        anchor.item: root.anchorItem
        anchor.rect.x: -((popupWindow.width - (root.anchorItem ? root.anchorItem.width : 32)) / 2)
        anchor.rect.y: (root.anchorItem ? root.anchorItem.height : 32) + 8
        visible: false
        
        property int padding: 8
        property int buttonHeight: 32
        
        implicitWidth: 140
        implicitHeight: buttonColumn.implicitHeight + padding * 2
        
        onVisibleChanged: {
            if (!visible) {
                focusGrab.active = false
            }
        }
        
        Column {
            id: buttonColumn
            anchors.fill: parent
            anchors.margins: popupWindow.padding
            spacing: 4
            
            // Open button
            Rectangle {
                width: parent.width
                height: popupWindow.buttonHeight
                radius: 6
                color: openMouseArea.containsMouse ? Colors.brighten_5 : "transparent"
                
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Fonts.iconMonitor
                        color: Colors.text
                        font.family: Fonts.iconFont
                        font.pixelSize: Fonts.h3
                    }
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Open"
                        color: Colors.text
                        font.pixelSize: Fonts.p
                    }
                }
                
                MouseArea {
                    id: openMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        // Move window to workspace 5 and focus it
                        moveWindowProcess.running = true;
                    }
                }
            }
            
            // Separator
            PopupSeparator {
                width: parent.width
                height: 8
            }
            
            // Close button
            Rectangle {
                width: parent.width
                height: popupWindow.buttonHeight
                radius: 6
                color: closeMouseArea.containsMouse ? Colors.brighten_5 : "transparent"
                
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Fonts.iconFalse
                        color: Colors.red
                        font.family: Fonts.iconFont
                        font.pixelSize: Fonts.h3
                    }
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Close"
                        color: Colors.red
                        font.pixelSize: Fonts.p
                    }
                }
                
                MouseArea {
                    id: closeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        // Close the window
                        closeWindowProcess.running = true;
                    }
                }
            }
        }
    }

    // Process to move window to workspace 5
    Process {
        id: moveWindowProcess
        running: false
        command: ["hyprctl", "dispatch", "movetoworkspacesilent", "5,address:" + root.formattedAddress]
        
        stdout: SplitParser {
            onRead: (data) => { }
        }
        
        stderr: SplitParser {
            onRead: (data) => { }
        }
        
        onExited: (exitCode) => {
            // Now focus the window
            focusWindowProcess.running = true;
        }
    }

    // Process to focus the window
    Process {
        id: focusWindowProcess
        running: false
        command: ["hyprctl", "dispatch", "focuswindow", "address:" + root.formattedAddress]
        
        stdout: SplitParser {
            onRead: (data) => { }
        }
        
        stderr: SplitParser {
            onRead: (data) => { }
        }
        
        onExited: (exitCode) => {
            root.actionTaken();
            popupWindow.visible = false;
        }
    }

    // Process to close the window
    Process {
        id: closeWindowProcess
        running: false
        command: ["hyprctl", "dispatch", "closewindow", "address:" + root.formattedAddress]
        
        stdout: SplitParser {
            onRead: (data) => { }
        }
        
        stderr: SplitParser {
            onRead: (data) => { }
        }
        
        onExited: (exitCode) => {
            root.actionTaken();
            popupWindow.visible = false;
        }
    }
}
