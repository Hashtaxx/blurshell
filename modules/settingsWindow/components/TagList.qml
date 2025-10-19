/**
 * TagList Component
 * 
 * Displays a collection of tags in a flow layout with inline add/remove functionality.
 * Users can click to remove existing tags or type and add new ones via return key or add button.
 * Supports duplicate prevention and custom styling for tags and buttons.
 * 
 * Usage:
 *   TagList {
 *       items: ["tag1", "tag2", "tag3"]
 *       placeholderText: "Enter new tag..."
 *       onItemAdded: (item) => console.log("Added:", item)
 *       onItemRemoved: (item) => console.log("Removed:", item)
 *   }
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.settings
import qs.components.animations

Item {
    id: root
    
    // Tag collection and display configuration
    property var items: []
    property string placeholderText: "Add item"
    
    // Visual styling for tags and buttons
    property color tagColor: Colors.brighten_5
    property color addButtonColor: Colors.green
    property color removeButtonColor: Colors.red
    
    // Layout dimensions
    readonly property int tagHeight: 28
    readonly property int tagRadius: 6
    readonly property int inputFieldWidth: 100
    readonly property int inputFieldHeight: 24
    readonly property int containerPadding: 16
    readonly property int containerSpacing: 8
    readonly property int tagHorizontalPadding: 8
    readonly property int containerExtraPadding: 8
    readonly property int focusBorderWidth: 1
    
    // Animation timing
    readonly property int focusAnimationDuration: AnimationConfig.fast
    
    // User interaction signals
    signal itemAdded(string item)
    signal itemRemoved(string item)
    
    implicitWidth: parent ? parent.width : 400
    implicitHeight: tagContainer.height
    
    // Helper function: validate and check for duplicates
    function isValidItem(item) {
        return item !== "" && !root.items.includes(item)
    }
    
    Rectangle {
        id: tagContainer
        width: parent.width
        height: tagFlow.height + (root.containerPadding * 2) + root.containerExtraPadding
        color: Colors.darken_20
        radius: root.containerSpacing
        
        Flow {
            id: tagFlow
            width: parent.width - (root.containerPadding * 2)
            spacing: root.containerSpacing
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: root.containerPadding
            }
            
            // Display existing tags with remove button
            Repeater {
                model: root.items
                
                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    
                    id: tagDelegate
                    height: root.tagHeight
                    width: itemText.width + removeBtn.width + (root.tagHorizontalPadding * 2)
                    color: root.tagColor
                    radius: root.tagRadius
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: root.containerExtraPadding
                        
                        // Tag text label
                        Text {
                            id: itemText
                            text: tagDelegate.modelData
                            color: Colors.text
                            font.pixelSize: Fonts.p
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: root.tagHorizontalPadding
                        }
                        
                        // Remove tag button
                        Text {
                            id: removeBtn
                            text: Fonts.iconFalse
                            color: root.removeButtonColor
                            font.pixelSize: Fonts.h3
                            font.family: Fonts.iconFont
                            anchors.verticalCenter: parent.verticalCenter
                            rightPadding: root.tagHorizontalPadding
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.itemRemoved(tagDelegate.modelData)
                            }
                        }
                    }
                }
            }
            
            // Input field and add button for new tags
            Rectangle {
                height: root.tagHeight
                width: newItemInput.width + addBtn.width + (root.tagHorizontalPadding * 2)
                color: root.tagColor
                radius: root.tagRadius
                border.color: newItemInput.activeFocus ? Colors.lavender : root.tagColor
                border.width: root.focusBorderWidth
                
                Behavior on border.color {
                    ColorAnimation {
                        duration: root.focusAnimationDuration
                    }
                }
                
                Row {
                    anchors.centerIn: parent
                    spacing: root.containerExtraPadding
                    
                    // Text input field for new tags
                    TextField {
                        id: newItemInput
                        width: root.inputFieldWidth
                        height: root.inputFieldHeight
                        placeholderText: root.placeholderText
                        color: Colors.text
                        font.pixelSize: Fonts.p
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        leftPadding: root.tagHorizontalPadding
                        rightPadding: root.containerExtraPadding
                        
                        background: Item {}
                        
                        Keys.onReturnPressed: {
                            let item = text.trim();
                            if (root.isValidItem(item)) {
                                root.itemAdded(item);
                                text = "";
                            }
                        }
                    }
                    
                    // Add new tag button
                    Text {
                        id: addBtn
                        text: Fonts.iconPlus
                        color: root.addButtonColor
                        font.pixelSize: Fonts.p
                        font.family: Fonts.iconFont
                        anchors.verticalCenter: parent.verticalCenter
                        rightPadding: root.tagHorizontalPadding
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let item = newItemInput.text.trim();
                                if (root.isValidItem(item)) {
                                    root.itemAdded(item);
                                    newItemInput.text = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
