// Tabs.qml
// Tab bar with smooth animated indicator that follows the active tab selection
pragma ComponentBehavior: Bound

import QtQuick
import qs.settings

Rectangle {
    id: root

    property int currentTab: 0
    property var tabModel: ["Apps", "Files", "Web"]
    property color activeColor: Config.launcherAccent
    property color inactiveColor: Colors.textSubdued
    property color activeBgColor: Colors.brighten_10
    property color inactiveBgColor: Colors.brighten_3

    signal tabChanged(int index)

    color: "transparent"
    implicitWidth: parent.width

    Row {
        id: tabRow
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.tabModel

            delegate: Rectangle {
                id: tabDelegate

                required property int index
                required property string modelData

                width: tabRow.width / root.tabModel.length
                height: parent.height
                radius: 8
                color: root.currentTab === tabDelegate.index ? "transparent" : tabMouseArea.containsMouse ? Colors.brighten_5 : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: tabDelegate.modelData
                    color: root.currentTab === tabDelegate.index ? root.activeColor : root.inactiveColor
                    font.pixelSize: Fonts.h5
                    font.bold: root.currentTab === tabDelegate.index
                }

                MouseArea {
                    id: tabMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        root.tabChanged(tabDelegate.index);
                    }
                }
            }
        }
    }

    // Animated bottom border
    Rectangle {
        id: bottomBorder
        height: 4
        width: (parent.width / root.tabModel.length) * 0.9
        color: root.activeColor
        anchors.bottom: parent.bottom
        x: root.currentTab * (parent.width / root.tabModel.length) + (parent.width / root.tabModel.length) * 0.05

        Behavior on x {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
    }
}
