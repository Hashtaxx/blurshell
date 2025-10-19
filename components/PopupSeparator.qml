// PopupSeparator.qml
// Horizontal separator line for dividing sections in popup menus and lists
pragma ComponentBehavior: Bound

import QtQuick
import qs.settings

Rectangle {
    id: root
    width: parent.width
    height: 3
    color: "transparent"

    Rectangle {
        id: separator
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.9
        height: 1
        color: Colors.brighten_20
        radius: 1
    }
}
