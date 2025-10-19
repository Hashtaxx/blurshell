/**
 * StyledButton Component
 * 
 * Interactive button with customizable text, icon, and multi-state styling.
 * Supports normal, hover, and pressed visual states with smooth color animations.
 * Icon can be positioned left or right of text label.
 * 
 * Usage:
 *   StyledButton {
 *       buttonText: "Save Settings"
 *       iconText: Fonts.iconSave
 *       bgColor: Colors.brighten_3
 *       onButtonClicked: applyChanges()
 *   }
 * 
 * State Color Hierarchy:
 *   - Pressed state takes priority (highest visual feedback)
 *   - Hover state used when mouse is over but not pressed
 *   - Normal state is default appearance
 */

pragma ComponentBehavior: Bound

import QtQuick
import qs.settings
import qs.components.animations

Item {
    id: root

    // Text and icon content
    property alias buttonText: buttonLabel.text
    property alias iconText: buttonIcon.text
    property bool iconOnRight: true  // Position: true = right of text, false = left of text

    // Layout configuration
    readonly property int buttonPadding: 8
    readonly property int borderRadius: 6
    readonly property int itemSpacing: 8

    // Normal state colors
    property color bgColor: "transparent"
    property color textColor: Colors.text
    property color iconColor: Colors.text

    // Pressed state colors (highest priority for visual feedback)
    property color bgColorPressed: Colors.brighten_5
    property color textColorPressed: Colors.text
    property color iconColorPressed: Colors.text

    // Hover state colors (used when mouse enters without pressing)
    property color bgColorHover: Colors.brighten_5
    property color textColorHover: Colors.text
    property color iconColorHover: Colors.text

    // Typography
    property int fontSize: Fonts.p

    // User interaction signal
    signal buttonClicked()

    implicitWidth: contentRow.implicitWidth + buttonPadding * 4
    implicitHeight: contentRow.implicitHeight + buttonPadding * 2

    // Background rectangle with state-dependent coloring
    Rectangle {
        id: background
        anchors.fill: parent
        color: mouseArea.pressed ? root.bgColorPressed : mouseArea.containsMouse ? root.bgColorHover : root.bgColor
        radius: root.borderRadius

        AnimatedColor on color {}
    }

    // Button content layout: icon and text
    Row {
        id: contentRow
        spacing: root.itemSpacing
        layoutDirection: root.iconOnRight ? Qt.LeftToRight : Qt.RightToLeft
        anchors.centerIn: parent

        // Button text label
        Text {
            id: buttonLabel
            text: "Button"
            color: mouseArea.pressed ? root.textColorPressed : mouseArea.containsMouse ? root.textColorHover : root.textColor
            font.pixelSize: root.fontSize
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter

            AnimatedColor on color {}
        }

        // Icon display (chevron down by default, customize via iconText property)
        Text {
            id: buttonIcon
            text: Fonts.iconChevronDown
            color: mouseArea.pressed ? root.iconColorPressed : mouseArea.containsMouse ? root.iconColorHover : root.iconColor
            font.family: Fonts.iconFont
            font.pixelSize: root.fontSize
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""

            AnimatedColor on color {}
        }
    }

    // Mouse interaction handler: click detection and hover effects
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.buttonClicked()
    }
}
