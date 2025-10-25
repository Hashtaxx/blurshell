// TrayIcon.qml
// Reusable tray icon with 3-tier fallback system
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.settings
import qs.components.animations
import Qt5Compat.GraphicalEffects

Item {
    id: root

    required property string iconName
    required property bool isHovered
    property real iconScale: 0.9

    // Primary icon from desktop entry
    Item {
        id: primaryIconContainer
        width: parent.height * root.iconScale
        height: parent.height * root.iconScale
        anchors.centerIn: parent
        visible: primaryIcon.source != ""

        Image {
            id: primaryIcon
            width: parent.width
            height: parent.height
            anchors.centerIn: parent
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            mipmap: true
            source: Quickshell.iconPath(root.iconName, true)
            scale: root.isHovered ? 0.95 : 0.9
            AnimatedScale on scale {}
        }

        layer.enabled: true
        layer.smooth: true
        layer.samples: 4
    }

    // Fallback 1: Try /usr/share/icons path
    Item {
        id: fallbackIconContainer
        width: parent.height * root.iconScale
        height: parent.height * root.iconScale
        anchors.centerIn: parent
        visible: !primaryIconContainer.visible && fallbackIcon.source != ""

        Image {
            id: fallbackIcon
            width: parent.width
            height: parent.height
            anchors.centerIn: parent
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            mipmap: true
            source: Quickshell.iconPath("/usr/share/icons/" + root.iconName, true)
            scale: root.isHovered ? 1 : 0.9
            AnimatedScale on scale {}
        }

        layer.enabled: true
        layer.smooth: true
        layer.samples: 4
    }

    // Fallback 2: Hyprland icon
    Item {
        id: fallbackTextContainer
        width: parent.height * root.iconScale
        height: parent.height * root.iconScale
        anchors.centerIn: parent
        visible: !primaryIconContainer.visible && !fallbackIconContainer.visible

        Text {
            id: fallbackText
            width: parent.width
            height: parent.height
            anchors.centerIn: parent
            text: Fonts.iconHyprland
            font.family: Fonts.iconFont
            font.pixelSize: parent.height * 0.5
            color: Colors.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            scale: root.isHovered ? 0.95 : 0.9
            AnimatedScale on scale {}
        }

        layer.enabled: true
        layer.smooth: true
        layer.samples: 4
    }
}
