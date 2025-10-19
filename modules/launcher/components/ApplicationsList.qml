pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.settings

/**
 * ApplicationsList: Displays searchable list of installed applications with action expansion
 *
 * Renders applications with name, description, and icon. Applications with available actions
 * display a chevron that expands to show additional actions. Left-click executes the app,
 * right-click expands actions. Keyboard navigation via inherited BaseListView logic.
 */
BaseListView {
    id: listView

    emptyMessage: "No applications found"
    emptySearchMessage: ""

    delegate: Column {
        id: itemColumn

        required property int index
        required property var modelData

        width: ListView.view.width
        spacing: 2

        readonly property bool isExpanded: !!(listView.logic.expandedItems[itemColumn.modelData.name])
        readonly property bool itemSelected: (itemColumn.index === listView.logic.currentItemIndex && listView.logic.currentActionIndex === -1)

        SelectableListItem {
            id: mainItem
            selected: itemColumn.itemSelected

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 14

                Image {
                    id: itemIcon
                    width: height
                    height: parent.height / 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    fillMode: Image.PreserveAspectFit
                    visible: itemIcon.source != ""
                    asynchronous: true
                    smooth: true
                    source: Quickshell.iconPath(itemColumn.modelData.icon, true)
                }

                // Fallback 1
                Image {
                    id: itemIconFallback
                    width: height
                    height: parent.height / 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    fillMode: Image.PreserveAspectFit
                    visible: !itemIcon.visible && itemIconFallback.source != ""
                    asynchronous: true
                    smooth: true
                    source: Quickshell.iconPath("/usr/share/icons/" + itemColumn.modelData.icon, true)
                }

                // Fallback 2
                Text {
                    id: itemIconFallbackText
                    width: height
                    height: parent.height / 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !itemIcon.visible && !itemIconFallback.visible
                    text: Fonts.iconHyprland
                    font.family: Fonts.iconFont
                    font.pixelSize: parent.height * 0.5
                    color: Colors.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: parent.width - itemIcon.width - itemChevron.width - (2 * parent.spacing)

                    Text {
                        text: itemColumn.modelData.name
                        color: Colors.text
                        font.pixelSize: Fonts.h5
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: itemColumn.modelData.comment || itemColumn.modelData.genericName || ""
                        visible: text.length > 0
                        width: parent.width
                        color: Colors.textSubdued
                        font.pixelSize: Fonts.p
                        elide: Text.ElideRight
                    }
                }

                Item {
                    id: itemChevron
                    width: height
                    height: parent.height
                    visible: itemColumn.modelData.actions && itemColumn.modelData.actions.length > 0

                    ExpandChevron {
                        anchors.fill: parent
                        expanded: itemColumn.isExpanded
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onPositionChanged: listView.logic.enableMouseSelection()

                onEntered: listView.logic.selectItem(itemColumn.index)

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton && itemColumn.modelData.actions && itemColumn.modelData.actions.length > 0) {
                        listView.logic.toggleExpansion(itemColumn.modelData.name);
                    } else {
                        listView.logic.executeApp(itemColumn.modelData);
                    }
                }
            }
        }

        Repeater {
            model: itemColumn.isExpanded && itemColumn.modelData.actions ? itemColumn.modelData.actions : []

            delegate: ActionListItem {
                id: actionItem

                required property int index
                required property var modelData

                readonly property bool actionSelected: (itemColumn.index === listView.logic.currentItemIndex && actionItem.index === listView.logic.currentActionIndex)

                selected: actionItem.actionSelected
                actionName: actionItem.modelData.name

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onPositionChanged: listView.logic.enableMouseSelection()

                    onEntered: listView.logic.selectAction(itemColumn.index, actionItem.index)

                    onClicked: listView.logic.executeAction(actionItem.modelData)
                }
            }
        }
    }
}