/**
 * LineSetting Component
 * 
 * A horizontal layout container for settings with a labeled icon on the left
 * and configurable content control on the right (e.g., Switch, Slider, Dropdown).
 * Automatically handles spacing and alignment.
 * 
 * Usage:
 *   LineSetting {
 *       labelText: "Volume"
 *       iconText: "🔊"
 *       content: Slider { ... }
 *   }
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.settings
import qs.components

Item {
    id: root

    // Layout properties
    property alias labelText: label.labelText
    property alias iconText: label.iconText
    property alias subTitle: subTitle.text

    // Content item (Dropdown, Switch, Slider, etc.)
    default property Item content

    // Styling properties
    property color textColor: Colors.text
    property color iconColor: Colors.text
    property int fontSize: Fonts.p

    // Layout dimensions
    property int spacing: 12
    property int horizontalPadding: 12
    property int minHeight: 50
    property int minContentWidth: 100
    property int cornerRadius: 8

    height: minHeight
    width: parent.width
    implicitWidth: label.implicitWidth + spacing + contentContainer.implicitWidth + (horizontalPadding * 2)
    implicitHeight: Math.max(label.implicitHeight, contentContainer.implicitHeight)

    Rectangle {
        id: background
        anchors.fill: parent
        color: Colors.darken_20
        radius: root.cornerRadius

        RowLayout {
            id: rowLayout
            anchors.fill: parent
            anchors.leftMargin: root.horizontalPadding
            anchors.rightMargin: root.horizontalPadding
            spacing: root.spacing

            Column {
                spacing: 4
            // Left side: icon and label text
            IconAndText {
                id: label
                labelText: "Setting Label"
                iconText: "\uefa8"
                iconColor: root.iconColor
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: false
            }
            Text {
                id: subTitle
                text: ""
                visible: subTitle.text != ""
                font.pixelSize: label.fontSize / 1.25
                color: Colors.textSubdued
            }
            }
            // Center spacer: stretches to fill available space
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: false
            }

            // Right side: content control container
            Item {
                id: contentContainer
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: false
                Layout.preferredWidth: {
                    if (!root.content)
                        return 0
                    let availableWidth = rowLayout.width - label.width - root.spacing * 3
                    return Math.min(root.content.implicitWidth, Math.max(availableWidth, root.minContentWidth))
                }
                implicitWidth: root.content ? root.content.implicitWidth : 0
                implicitHeight: root.content ? root.content.implicitHeight : 0
                clip: true

                Component.onCompleted: {
                    if (root.content) {
                        root.content.parent = contentContainer
                        root.content.anchors.verticalCenter = contentContainer.verticalCenter
                        root.content.anchors.right = contentContainer.right
                    }
                }
            }
        }
    }
}
