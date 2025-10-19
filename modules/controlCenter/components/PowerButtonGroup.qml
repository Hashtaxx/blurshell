pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.settings
import qs.components

Item {
    id: root
    implicitWidth: showingDialog ? confirmDialog.implicitWidth : actionButtonsWrapper.implicitWidth
    implicitHeight: showingDialog ? confirmDialog.implicitHeight : actionButtonsWrapper.implicitHeight

    property bool showingDialog: false
    property string pendingAction: ""
    property string actionLabel: ""

    function showConfirmDialog(action: string, label: string) {
        pendingAction = action;
        actionLabel = label;
        showingDialog = true;
    }

    function executeAction() {
        if (pendingAction === "suspend") {
            Quickshell.execDetached({
                command: ["qs", "ipc", "call", "state", "lockScreen"]
            });
            Quickshell.execDetached({
                command: ["sh", "-c", "sleep 2 && systemctl suspend"]
            });
        } else if (pendingAction === "reboot") {
            Quickshell.execDetached({
                command: ["systemctl", "reboot"]
            });
        } else if (pendingAction === "poweroff") {
            Quickshell.execDetached({
                command: ["systemctl", "poweroff"]
            });
        }
        showingDialog = false;
    }

    function cancelAction() {
        showingDialog = false;
        pendingAction = "";
        actionLabel = "";
    }

    // Power buttons - shown when no dialog is active
    Row {
        id: actionButtonsWrapper
        spacing: 8
        height: root.height
        visible: !root.showingDialog

        ActionButton {
            icon: Fonts.iconSleep
            backgroundColor: "transparent"
            onClicked: function () {
                root.showConfirmDialog("suspend", "Suspend");
            }
        }

        // Reboot button
        ActionButton {
            icon: Fonts.iconReboot
            backgroundColor: "transparent"
            onClicked: function () {
                root.showConfirmDialog("reboot", "Reboot");
            }
        }

        // Power off button
        ActionButton {
            icon: Fonts.iconPowerOff
            backgroundColor: Config.controlCenterAccent
            borderColor: Config.controlCenterAccent
            textColor: Colors.textSecondary
            onClicked: function () {
                root.showConfirmDialog("poweroff", "Power Off");
            }
        }
    }

    // Confirmation dialog - shown when an action is pending
    Row {
        id: confirmDialog
        spacing: 8
        height: root.height
        visible: root.showingDialog

        // "Confirm?" text
        Text {
            text: "Confirm? "
            color: Colors.text
            font.pixelSize: Fonts.h4
            anchors.verticalCenter: parent.verticalCenter
        }

        // Cancel button
        ActionButton {
            icon: Fonts.iconFalse
            backgroundColor: "transparent"
            borderColor: Colors.red
            textColor: Colors.red
            onClicked: function () {
                root.cancelAction();
            }
        }

        // Confirm button
        ActionButton {
            icon: Fonts.iconTrue
            backgroundColor: Config.controlCenterAccent
            borderColor: Config.controlCenterAccent
            textColor: Colors.textSecondary
            onClicked: function () {
                root.executeAction();
            }
        }
    }
}
