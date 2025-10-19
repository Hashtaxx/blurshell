pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.settings
import qs.components
import qs.components.animations

Background {
    id: root

    visible: trayRepeater.count > 0

    Row {
        id: trayRow
        spacing: Config.gapsIn
        height: parent.height
        anchors.centerIn: parent

        Repeater {
            id: trayRepeater
            model: SystemTray.items

            delegate: Item {
                id: trayItem
                required property SystemTrayItem modelData

                width: parent ? parent.height : 32
                height: parent ? parent.height : 32

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function (mouse) {
                        // If item has a menu, show it on any click
                        if (trayItem.modelData.hasMenu) {
                            qsMenu.menu = trayItem.modelData.menu;
                            qsMenu.anchorItem = trayItem;
                            qsMenu.open();
                        } else {
                            // No menu, use standard actions
                            if (mouse.button === Qt.LeftButton) {
                                trayItem.modelData.activate();
                            } else if (mouse.button === Qt.RightButton) {
                                trayItem.modelData.activate();
                            } else if (mouse.button === Qt.MiddleButton) {
                                trayItem.modelData.secondaryActivate();
                            }
                        }
                    }

                    onWheel: function (wheel) {
                        trayItem.modelData.scroll(wheel.angleDelta.y, false); // false = vertical
                    }

                    Image {
                        id: icon
                        anchors.centerIn: parent
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: this.height
                        height: parent.height
                        source: trayItem.modelData.icon
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        cache: false  // Disable cache to handle icon updates better
                        scale: parent.containsMouse ? 0.88 : 0.8
                        AnimatedScale on scale {}
                        onStatusChanged: {
                            if (status === Image.Error) {
                                icon.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }

    // Shared QsMenu for all tray items
    QsMenu {
        id: qsMenu
    }
}
