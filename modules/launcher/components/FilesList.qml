pragma ComponentBehavior: Bound

import QtQuick
import qs.settings

BaseListView {
    id: listView

    // Optional properties (logic is inherited from BaseListView)
    emptyMessage: "No files found"
    emptySearchMessage: ""

    delegate: Column {
        id: fileColumn
        required property int index
        required property var modelData

        width: ListView.view.width
        spacing: 2

        readonly property bool isExpanded: !!(listView.logic.expandedItems[fileColumn.modelData.path])
        readonly property bool itemSelected: (fileColumn.index === listView.logic.currentItemIndex && listView.logic.currentActionIndex === -1)

        // Main item
        SelectableListItem {
            id: mainItem
            selected: fileColumn.itemSelected

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 14

                // File/Folder icon
                Item {
                    id: fileIcon
                    width: height
                    height: parent.height / 1.5
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: fileColumn.modelData.isDirectory ? "󰉋" : "󰈔"
                        color: fileColumn.modelData.isDirectory ? Colors.blue : Colors.textSubdued
                        font.pixelSize: 24
                        font.family: Fonts.iconFont
                    }
                }

                // File Info
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: parent.width - fileIcon.width - fileChevron.width - (2 * parent.spacing)

                    Text {
                        text: fileColumn.modelData.name
                        color: Colors.text
                        font.pixelSize: Fonts.h5
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: fileColumn.modelData.isDirectory ? (fileColumn.modelData.path + "/") : fileColumn.modelData.path
                        visible: text.length > 0
                        width: parent.width
                        color: Colors.textSubdued
                        font.pixelSize: Fonts.p
                        elide: Text.ElideMiddle
                    }
                }

                // Chevron for actions
                Item {
                    id: fileChevron
                    width: height
                    height: parent.height
                    visible: true  // Always visible since all files have actions

                    ExpandChevron {
                        anchors.fill: parent
                        expanded: fileColumn.isExpanded
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onPositionChanged: {
                    // Re-enable mouse selection when mouse actually moves
                    listView.logic.enableMouseSelection();
                }

                onEntered: listView.logic.selectItem(fileColumn.index)

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        listView.logic.toggleExpansion(fileColumn.modelData.path);
                    } else {
                        // Left click executes the file
                        listView.logic.executeFile(fileColumn.modelData);
                    }
                }
            }
        }

        // Actions (shown when expanded)
        Repeater {
            model: fileColumn.isExpanded ? listView.logic.fileActions : []

            delegate: ActionListItem {
                id: actionItem

                required property int index
                required property var modelData

                readonly property bool actionSelected: (fileColumn.index === listView.logic.currentItemIndex && actionItem.index === listView.logic.currentActionIndex)

                selected: actionItem.actionSelected
                actionName: actionItem.modelData.name

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onPositionChanged: {
                        // Re-enable mouse selection when mouse actually moves
                        listView.logic.enableMouseSelection();
                    }

                    onEntered: listView.logic.selectAction(fileColumn.index, actionItem.index)

                    onClicked: {
                        listView.logic.executeItemAction(actionItem.modelData, fileColumn.modelData);
                    }
                }
            }
        }
    }
}
