/**
 * MapEditor Component
 * 
 * A key-value pair editor for managing map/object data with dynamic row management.
 * Displays existing items with read-only keys and editable values, provides an input row
 * to add new key-value pairs. Emits signals on add, update, and remove operations.
 * Supports Unicode escape sequence parsing in values.
 * 
 * Usage:
 *   MapEditor {
 *       items: { "key1": "value1", "key2": "value2" }
 *       onItemAdded: (key, value) => console.log("Added:", key, value)
 *       onItemRemoved: (key) => console.log("Removed:", key)
 *   }
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.settings

Column {
    id: root
    spacing: 8

    // Data model
    property var items: ({})

    // Input placeholders
    property string keyPlaceholder: "Key"
    property string valuePlaceholder: "Value"

    // Color scheme
    property color backgroundColor: Colors.darken_20
    property color inputBackgroundColor: Colors.brighten_10
    property color borderColor: Colors.bg
    property color focusBorderColor: Colors.lavender
    property color textColor: Colors.text
    property color subtleTextColor: Colors.textSubdued
    property color addButtonColor: Colors.green
    property color removeButtonColor: Colors.red

    // Layout dimensions
    property int cornerRadius: 8
    property int rowSpacing: 8
    property int rowHeight: 40
    property int containerPadding: 16
    property int minContainerHeight: 80
    property int containerRowSpacing: 8
    property int fieldRadius: 6
    property int iconFontSize: 16
    property int fieldPadding: 4

    signal itemAdded(string key, string value)
    signal itemUpdated(string key, string value)
    signal itemRemoved(string key)

    // Convert Unicode escape sequences (e.g., \uXXXX) to actual characters
    function parseUnicodeEscapes(str) {
        return str.replace(/\\u([0-9a-fA-F]{4})/g, function(match, hex) {
            return String.fromCharCode(parseInt(hex, 16));
        });
    }

    // Validate and add new item
    function addNewItem(key = "", value = "") {
        const trimmedKey = String(key).trim();
        if (trimmedKey !== "") {
            root.itemAdded(trimmedKey, parseUnicodeEscapes(String(value).trim()));
        }
    }

    Rectangle {
        width: parent.width
        height: Math.max(contentColumn.height + (root.containerPadding * 2), root.minContainerHeight)
        color: root.backgroundColor
        radius: root.cornerRadius

        Column {
            id: contentColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: root.containerPadding
            }
            spacing: root.containerRowSpacing

            // Display existing key-value pairs
            Repeater {
                model: Object.keys(root.items)

                delegate: Row {
                    id: delegateRoot
                    required property string modelData
                    width: parent.width
                    spacing: root.rowSpacing
                    height: root.rowHeight

                    // Read-only key display
                    Rectangle {
                        width: (parent.width * 0.5) - removeIcon.width
                        height: parent.height
                        color: root.inputBackgroundColor
                        radius: root.fieldRadius

                        Text {
                            text: delegateRoot.modelData
                            color: root.subtleTextColor
                            font.pixelSize: Fonts.p
                            anchors.centerIn: parent
                            elide: Text.ElideRight
                            width: parent.width - (root.fieldPadding * 2)
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    // Editable value field
                    TextField {
                        width: (parent.width * 0.5) - removeIcon.width
                        height: parent.height
                        text: root.items[delegateRoot.modelData] || ""
                        color: root.textColor
                        font.pixelSize: Fonts.p
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        leftPadding: root.fieldPadding
                        rightPadding: root.fieldPadding

                        background: Rectangle {
                            color: root.inputBackgroundColor
                            radius: root.fieldRadius
                        }

                        onEditingFinished: root.itemUpdated(delegateRoot.modelData, parseUnicodeEscapes(text))
                    }

                    // Remove button
                    Text {
                        id: removeIcon
                        text: Fonts.iconFalse
                        color: root.removeButtonColor
                        font.pixelSize: root.iconFontSize
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.itemRemoved(delegateRoot.modelData)
                        }
                    }
                }
            }

            // Input row for adding new items
            Row {
                width: parent.width
                spacing: root.rowSpacing
                height: root.rowHeight

                TextField {
                    id: newKeyInput
                    width: (parent.width * 0.5) - addIcon.width
                    height: parent.height
                    placeholderText: root.keyPlaceholder
                    color: root.textColor
                    font.pixelSize: Fonts.p
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    leftPadding: root.fieldPadding
                    rightPadding: root.fieldPadding

                    background: Rectangle {
                        color: root.inputBackgroundColor
                        radius: root.fieldRadius
                        border.color: parent.activeFocus ? root.focusBorderColor : "transparent"
                        border.width: 1
                    }

                    Keys.onReturnPressed: newValueInput.focus = true
                }

                TextField {
                    id: newValueInput
                    width: (parent.width * 0.5) - addIcon.width
                    height: parent.height
                    placeholderText: root.valuePlaceholder
                    color: root.textColor
                    font.pixelSize: Fonts.p
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    leftPadding: root.fieldPadding
                    rightPadding: root.fieldPadding

                    background: Rectangle {
                        color: root.inputBackgroundColor
                        radius: root.fieldRadius
                        border.color: parent.activeFocus ? root.focusBorderColor : "transparent"
                        border.width: 1
                    }

                    Keys.onReturnPressed: {
                        root.addNewItem(newKeyInput.text, newValueInput.text);
                        newKeyInput.text = "";
                        newValueInput.text = "";
                        newKeyInput.focus = true;
                    }
                }

                // Add button
                Text {
                    id: addIcon
                    text: Fonts.iconPlus
                    color: root.addButtonColor
                    font.pixelSize: root.iconFontSize
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.addNewItem(newKeyInput.text, newValueInput.text);
                            newKeyInput.text = "";
                            newValueInput.text = "";
                            newKeyInput.focus = true;
                        }
                    }
                }
            }
        }
    }
}