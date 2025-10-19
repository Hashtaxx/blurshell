pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell
import qs.settings
import qs.components.animations
import qs.services

/**
 * Displays transient reload notification popups for Quickshell configuration reloads.
 *
 * Handles both success and failure scenarios with visual feedback:
 * - Success: Green indicator, 1-second auto-dismiss
 * - Failure: Red indicator with error details, 10-second duration
 *
 * Features:
 * - Lazy-loaded for performance (only created when needed)
 * - Slide-in animation with progress bar countdown
 * - Auto-dismiss or click-to-dismiss functionality
 * - Manages drawer focus state via DrawerFocusManager
 */
Scope {
    id: root

    property bool failed
    property string errorString

    // Layout and sizing constants
    readonly property real windowMarginHorizontal: 10
    readonly property real contentPadding: 12
    readonly property real contentSpacing: 8
    readonly property real textSpacing: 4
    readonly property real iconSize: 48
    readonly property real iconRadius: 8
    readonly property real progressBarHeight: 5
    readonly property real progressBarRadius: 9999
    readonly property real slideDistance: 20
    readonly property real cornerRadius: 12

    // Animation durations (milliseconds)
    readonly property int slideInDuration: 200
    readonly property int successDuration: 1000
    readonly property int failureDuration: 10000

    // Listen for Quickshell reload events and manage popup lifecycle
    Connections {
        target: Quickshell

        function onReloadCompleted() {
            root.failed = false
            popupLoader.active = true
        }

        function onReloadFailed(error: string) {
            // Replace any existing popup with fresh failure state
            popupLoader.active = false
            root.failed = true
            root.errorString = error
            popupLoader.active = true
        }
    }


    // On-demand loader to prevent unnecessary resource allocation
    LazyLoader {
        id: popupLoader

        onActiveChanged: {
            if (!active) {
                DrawerFocusManager.notifyPopupClosed()
            }
        }

        PanelWindow {
            id: popup

            exclusiveZone: 0
            anchors {
                top: true
                left: true
            }
            margins {
                top: Config.gapsOut
                left: Config.gapsOut + root.windowMarginHorizontal
            }

            implicitWidth: reloadRect.width + 20
            implicitHeight: reloadRect.implicitHeight

            color: "transparent"

            Rectangle {
                id: reloadRect
                width: 380
                implicitHeight: contentLayout.implicitHeight + padding * 2

                property real padding: root.contentPadding

                radius: root.cornerRadius
                color: mouseArea.containsMouse ? Colors.bg : Colors.bgBlur

                AnimatedColor on color {}

                // Clickable area to dismiss popup
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: popupLoader.active = false
                }

                ColumnLayout {
                    id: contentLayout
                    anchors.fill: parent
                    anchors.margins: reloadRect.padding
                    spacing: root.contentSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Status icon with conditional coloring based on reload result
                        Rectangle {
                            Layout.preferredWidth: root.iconSize
                            Layout.preferredHeight: root.iconSize
                            Layout.alignment: Qt.AlignTop
                            radius: root.iconRadius
                            color: root.failed ? Qt.alpha(Colors.red, 0.2) : Qt.alpha(Colors.green, 0.2)

                            AnimatedColor on color {}

                            Text {
                                anchors.centerIn: parent
                                text: root.failed ? Fonts.iconFalse : Fonts.iconTrue
                                font.family: Fonts.iconFont
                                font.pixelSize: 24
                                color: root.failed ? Colors.red : Colors.green

                                AnimatedColor on color {}
                            }
                        }

                        // Status title and error details
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: root.textSpacing

                            Text {
                                Layout.fillWidth: true
                                text: root.failed ? "Quickshell: Reload failed" : "Quickshell reloaded"
                                color: Colors.text
                                font.pixelSize: Fonts.p
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap

                                AnimatedColor on color {}
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.errorString
                                color: Colors.textSubdued
                                font.pixelSize: Fonts.h6
                                wrapMode: Text.Wrap
                                maximumLineCount: 6
                                elide: Text.ElideRight
                                visible: root.errorString !== ""

                                AnimatedColor on color {}
                            }
                        }
                    }

                    // Animated progress bar that triggers auto-dismiss on completion
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.progressBarHeight
                        Layout.topMargin: 4

                        // Background track
                        Rectangle {
                            id: barBg
                            anchors.fill: parent
                            radius: root.progressBarRadius
                            color: root.failed ? Qt.alpha(Colors.red, 0.2) : Qt.alpha(Colors.green, 0.2)

                            AnimatedColor on color {}
                        }

                        // Animated progress indicator
                        Rectangle {
                            id: bar
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            radius: root.progressBarRadius
                            color: root.failed ? Colors.red : Colors.green

                            AnimatedColor on color {}

                            PropertyAnimation {
                                id: anim
                                target: bar
                                property: "width"
                                from: barBg.width
                                to: 0
                                duration: root.failed ? root.failureDuration : root.successDuration
                                onFinished: popupLoader.active = false
                                // Pause animation on hover to let user read error details
                                paused: mouseArea.containsMouse
                            }
                        }
                    }
                }

                // Entry animation setup
                opacity: 0
                x: -root.slideDistance

                Component.onCompleted: {
                    anim.start()
                    slideInAnim.start()
                }

                // Parallel slide-in and fade-in animation on entry
                ParallelAnimation {
                    id: slideInAnim
                    NumberAnimation {
                        target: reloadRect
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: root.slideInDuration
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: reloadRect
                        property: "x"
                        from: -root.slideDistance
                        to: 0
                        duration: root.slideInDuration
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
}
