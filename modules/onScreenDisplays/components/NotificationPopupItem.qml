pragma ComponentBehavior: Bound

/**
 * Dismissible notification popup item with timer and drag-to-dismiss
 *
 * Displays a single notification in a draggable, auto-dismissing card. Features:
 * - Hover state tracking with background color transitions
 * - Auto-dismiss countdown timer with visual progress indicator
 * - Drag-to-dismiss gesture with snap-back fallback
 * - Action button support for notification interactions
 * - Smooth fly-in animation on creation
 */

import QtQuick
import QtQuick.Layouts
import qs.settings
import qs.services
import qs.components.notifications

Rectangle {
    id: root

    required property var notificationObject

    property real padding: 12
    property real cornerRadius: 12

    implicitHeight: contentLayout.implicitHeight + padding * 2
    implicitWidth: 380

    radius: cornerRadius
    color: hoverHandler.hovered ? Colors.bg : Colors.bgBlur

    HoverHandler {
        id: hoverHandler
    }

    // Slide animation with drag-to-dismiss gesture support
    DismissibleSlideAnimation {
        id: slideAnimation
        target: root

        onDismissed: {
            const notifId = root.notificationObject?.notificationId;
            if (notifId !== undefined) {
                Qt.callLater(() => {
                    Notifications.discardNotification(notifId);
                });
            }
        }

        onClicked: mouse => {
            // Invoke default action if it exists
            const actions = root.notificationObject?.actions || [];
            const defaultAction = actions.find(action => action.identifier === "default");
            if (defaultAction) {
                const notifId = root.notificationObject?.notificationId;
                if (notifId !== undefined) {
                    Notifications.attemptInvokeAction(notifId, "default");
                }
            }
        }

        onRightClicked: mouse => {
            const notifId = root.notificationObject?.notificationId;
            if (notifId !== undefined) {
                Notifications.discardNotification(notifId);
            }
        }
    }

    // Initial state for fly-in animation
    Component.onCompleted: {
        slideAnimation.startFlyIn();
    }

    // Expose drag and dismiss state for external access
    property real dragDistance: slideAnimation.dragDistance
    property bool dismissing: slideAnimation.dismissing
    property real dragThreshold: slideAnimation.dragThreshold
    readonly property bool isDragging: slideAnimation.dragging

    // Hover state tracking for timer pause/resume and background color change
    Connections {
        target: hoverHandler
        function onHoveredChanged() {
            const notifId = root.notificationObject?.notificationId;
            if (!notifId)
                return;
            if (hoverHandler.hovered) {
                // Pause timer when hovering to prevent auto-dismiss
                Notifications.cancelTimeout(notifId);
                if (root.timerAnimation?.running && !root.isDragging) {
                    root.timerAnimation.pause();
                }
            } else {
                // Resume timer when mouse leaves (but not during drag)
                Notifications.timeoutNotification(notifId);
                if (!root.isDragging && root.timerAnimation && root.timerCanvas) {
                    root.timerAnimation.stop();
                    root.timerCanvas.progress = 1.0;
                    root.timerAnimation.start();
                }
            }
        }
    }

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 12
        z: 1

        // Notification icon or image
        NotificationIcon {
            id: notifIcon
            Layout.alignment: contentColumn.implicitHeight > 48 ? Qt.AlignTop : Qt.AlignVCenter
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            image: root.notificationObject?.image || ""
            appIcon: root.notificationObject?.appIcon || ""
            showImage: true
        }

        // Notification content with timer and actions
        NotificationContent {
            id: contentColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            notificationObject: root.notificationObject
            isGroup: false
            showTimestamp: false
            showDismissButton: true
            dismissButtonSize: 18 * 1.10
            titleFontSize: Fonts.p
            bodyFontSize: Fonts.h6
            titleFontWeight: Font.DemiBold
            titleColor: Colors.text
            bodyColor: Colors.textSubdued
            maxBodyLines: 4

            // Timer visualization component
            timerComponent: Component {
                Canvas {
                    id: timerCanvas

                    property real progress: 1.0

                    onProgressChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();

                        var centerX = width / 2;
                        var centerY = height / 2;
                        var radius = Math.min(width, height) / 2;

                        if (progress > 0) {
                            ctx.beginPath();
                            ctx.moveTo(centerX, centerY);
                            ctx.arc(centerX, centerY, radius, -Math.PI / 2, (-Math.PI / 2) + (progress * 2 * Math.PI), false);
                            ctx.lineTo(centerX, centerY);
                            ctx.fillStyle = Colors.red;
                            ctx.globalAlpha = 1;
                            ctx.fill();
                        }
                    }

                    // Progress animation controlled by notification timeout
                    NumberAnimation {
                        id: timerAnimation
                        target: timerCanvas
                        property: "progress"
                        from: 1.0
                        to: 0.0
                        duration: {
                            const timeout = root.notificationObject?.notification?.expireTimeout;
                            return (timeout && timeout > 0) ? timeout : 5000;
                        }
                        running: false

                        onFinished: {
                            if (!hoverHandler.hovered) {
                                slideAnimation.startDismiss();
                            }
                        }

                        Component.onCompleted: {
                            timerAnimation.start();
                        }
                    }

                    // Expose timer for hover management
                    Component.onCompleted: {
                        root.timerAnimation = timerAnimation;
                        root.timerCanvas = timerCanvas;
                    }
                }
            }

            onDismissRequested: {
                slideAnimation.startDismiss();
            }
        }
    }

    // References to timer components for hover-based pause/resume
    property var timerAnimation: null
    property var timerCanvas: null

    // Enable shadow effect for visual depth
    layer.enabled: true
    layer.smooth: true
}
