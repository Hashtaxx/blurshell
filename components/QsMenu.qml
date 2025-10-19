// QsMenu.qml
// Displays context menus with checkbox, radio button, and action items
// Handles menu popup positioning, item interaction, and focus management
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.settings

Item {
    id: root
    
    // The QsMenuHandle to display
    property var menu: null
    
    // The item to anchor the popup to
    property var anchorItem: null
    
    // Read-only property to check visibility
    readonly property bool isVisible: popupMenu.visible
    
    // Signal emitted when a menu item is clicked
    signal itemClicked(var menuEntry)
    
    // Function to open the menu
    function open() {
        if (anchorItem) {
            popupMenu.visible = true
            focusGrab.active = true
        }
    }
    
    // Function to close the menu
    function close() {
        popupMenu.visible = false
        focusGrab.active = false
    }
    
    HyprlandFocusGrab {
        id: focusGrab
        windows: [popupMenu]
        onCleared: {
            popupMenu.visible = false
        }
    }
    
    QsMenuOpener {
        id: menuOpener
        menu: root.menu
    }
    
    // Menu popup
    Popup {
        id: popupMenu
        anchor.item: root.anchorItem
        anchor.rect.x: -((popupMenu.width - (root.anchorItem ? root.anchorItem.width : 32)) / 2)
        anchor.rect.y: (root.anchorItem ? root.anchorItem.height : 32) + 8
        visible: false
        
        property int padding: 8
        property int minWidth: 120
        property real maxChildWidth: 0
        
        implicitWidth: Math.max(minWidth, maxChildWidth + padding * 2)
        implicitHeight: menuColumn.implicitHeight + padding * 2
        
        onVisibleChanged: {
            if (!visible) {
                focusGrab.active = false
                // Don't reset maxChildWidth - keep it for next opening
            }
        }
        
        Column {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: popupMenu.padding
            spacing: 2
            
            Repeater {
                id: menuRepeater
                model: menuOpener.children
                
                Item {
                    id: itemDelegate
                    required property var modelData
                    required property int index
                    
                    width: parent.width
                    height: modelData.isSeparator ? 8 : 32
                    
                    // Separator
                    PopupSeparator {
                        anchors.fill: parent
                        visible: itemDelegate.modelData.isSeparator
                    }
                    
                    // Regular menu item
                    Rectangle {
                        anchors.fill: parent
                        visible: !itemDelegate.modelData.isSeparator
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
                            
                            // Checkbox/Radio button indicator
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    if (itemDelegate.modelData.buttonType === QsMenuButtonType.CheckBox) {
                                        return itemDelegate.modelData.checkState === Qt.Checked ? Fonts.iconCheckboxChecked : Fonts.iconCheckboxUnchecked
                                    } else if (itemDelegate.modelData.buttonType === QsMenuButtonType.RadioButton) {
                                        return itemDelegate.modelData.checkState === Qt.Checked ? Fonts.iconRadioChecked : Fonts.iconRadioUnchecked
                                    }
                                    return ""
                                }
                                color: Colors.text
                                font.family: Fonts.iconFont
                                font.pixelSize: Fonts.h3
                                visible: text !== ""
                            }
                            
                            // Icon
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                source: itemDelegate.modelData.icon
                                sourceSize.width: 16
                                sourceSize.height: 16
                                width: 16
                                height: 16
                                visible: itemDelegate.modelData.icon !== ""
                            }
                            
                            // Text
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: itemDelegate.modelData.text
                                color: itemDelegate.modelData.enabled ? Colors.text : Colors.brighten_20
                                font.pixelSize: Fonts.p
                                elide: Text.ElideRight
                            }
                            
                            // Submenu indicator
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Fonts.iconChevronRight
                                color: Colors.text
                                font.family: Fonts.iconFont
                                font.pixelSize: Fonts.h4
                                visible: itemDelegate.modelData.hasChildren
                            }
                        }
                        
                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: itemDelegate.modelData.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                            enabled: itemDelegate.modelData.enabled
                            
                            onClicked: {
                                if (itemDelegate.modelData.enabled) {
                                    itemDelegate.modelData.triggered()
                                    root.itemClicked(itemDelegate.modelData)
                                    popupMenu.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
