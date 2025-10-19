pragma ComponentBehavior: Bound
import QtQuick
import qs.settings

Rectangle {
    id: root

    // Styling properties
    property color chipColor: Colors.bgBlur
    property int chipRadius: Config.barHeight / 3
    property int padding: Config.gapsOut * 2

    // Content
    default property alias contentData: contentItem.data
    property alias contentItem: contentItem

    // Sizing
    implicitWidth: contentItem.childrenRect.width + padding
    implicitHeight: parent ? parent.height : 32

    color: chipColor
    radius: chipRadius

    Item {
        id: contentItem
        anchors.centerIn: parent
        width: childrenRect.implicitWidth
        height: parent.height
    }
}
