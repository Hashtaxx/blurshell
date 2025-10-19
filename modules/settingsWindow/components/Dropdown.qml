// Dropdown.qml
// Styled dropdown menu with icon support and configurable items
// Features: focus grab management, customizable styling, separator support
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.settings

Item {
    id: root
    
    property alias buttonText: dropdownButton.buttonText
    property int buttonWidth: 150
    
    // Data model array with items containing: itemText, itemIcon, itemIconColor, isSeparator, itemAction
    property var model: []
    
    // Emitted when a menu item is clicked with action type and associated data
    signal itemClicked(string action, var data)
    
    implicitWidth: dropdownButton.implicitWidth
    implicitHeight: dropdownButton.implicitHeight
    
    HyprlandFocusGrab {
        id: focusGrab
        windows: [popupMenu]
        active: popupMenu.visible
        onCleared: {
            popupMenu.visible = false
        }
    }
    
    StyledButton {
        id: dropdownButton
        buttonText: "Select"
        iconText: Fonts.iconChevronDown
        iconOnRight: true
        anchors.fill: parent
        
        onButtonClicked: {
            const newVisibility = !popupMenu.visible
            popupMenu.visible = newVisibility
            focusGrab.active = newVisibility
        }
    }
    
    Popup {
        id: popupMenu
        anchor.item: dropdownButton
        anchor.rect.x: -((popupMenu.width - dropdownButton.width) / 2)
        anchor.rect.y: dropdownButton.height + 8
        visible: false
        
        property int padding: 8
        property int minWidth: Math.max(120, dropdownButton.width)
        property real maxChildWidth: 0
        
        implicitWidth: Math.max(minWidth, maxChildWidth + padding * 2)
        implicitHeight: contentColumn.implicitHeight + padding * 2
        
        onVisibleChanged: {
            if (!visible) {
                focusGrab.active = false
            }
        }
        
        Column {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: popupMenu.padding
            spacing: 2
            
            Repeater {
                id: repeater
                model: root.model
                
                Item {
                    id: itemDelegate
                    required property string itemText
                    required property string itemIcon
                    required property color itemIconColor
                    required property bool isSeparator
                    required property string itemAction
                    required property int index
                    
                    width: parent.width
                    height: isSeparator ? 8 : 32
                    
                    PopupSeparator {
                        anchors.fill: parent
                        visible: itemDelegate.isSeparator
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        visible: !itemDelegate.isSeparator
                        radius: 6
                        color: itemMouseArea.containsMouse ? Colors.brighten_5 : "transparent"
                        
                        Row {
                            id: itemRow
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            
                            Component.onCompleted: {
                                popupMenu.maxChildWidth = Math.max(popupMenu.maxChildWidth, implicitWidth + 16)
                            }
                            
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: itemDelegate.itemIcon
                                color: itemDelegate.itemIconColor
                                font.family: Fonts.iconFont
                                font.pixelSize: Fonts.h2
                                visible: itemDelegate.itemIcon !== ""
                            }
                            
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: itemDelegate.itemText
                                color: Colors.text
                                font.pixelSize: Fonts.p
                                elide: Text.ElideRight
                            }
                        }
                        
                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.itemClicked(itemDelegate.itemAction, {
                                    text: itemDelegate.itemText,
                                    icon: itemDelegate.itemIcon,
                                    index: itemDelegate.index
                                })
                                popupMenu.visible = false
                                focusGrab.active = false
                            }
                        }
                    }
                }
            }
        }
    }
}
