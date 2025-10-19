pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.settings

BaseListView {
    id: listView

    // Optional properties (logic is inherited from BaseListView)
    emptyMessage: "No search engines found"
    emptySearchMessage: ""

    delegate: SelectableListItem {
        id: itemDelegate

        required property int index
        required property var modelData

        readonly property bool itemSelected: (itemDelegate.index === listView.logic.currentItemIndex)

        selected: itemSelected

        Row {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 14

            // Search Engine Icon
            Image {
                id: engineIcon
                width: height
                height: parent.height / 1.5
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                smooth: true
                source: itemDelegate.modelData.icon

                // Fallback for missing icons
                onStatusChanged: {
                    if (status === Image.Error) {
                        source = Quickshell.iconPath("internet-web-browser");
                    }
                }
            }

            // Engine Info
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                width: parent.width - engineIcon.width - parent.spacing

                Text {
                    text: itemDelegate.modelData.name
                    color: Colors.text
                    font.pixelSize: Fonts.h5
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: itemDelegate.modelData.description || ""
                    visible: text.length > 0
                    width: parent.width
                    color: Colors.textSubdued
                    font.pixelSize: Fonts.p
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton

            onPositionChanged: {
                // Re-enable mouse selection when mouse actually moves
                listView.logic.enableMouseSelection();
            }

            onEntered: listView.logic.selectItem(itemDelegate.index)

            onClicked: {
                // Execute search with this engine
                listView.logic.executeSearch(itemDelegate.modelData, listView.logic.searchText.trim());
            }
        }
    }
}
