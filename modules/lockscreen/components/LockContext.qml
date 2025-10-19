pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Pam

// LockContext: Manages shared state and PAM authentication across all lock surfaces
Scope {
    id: root

    // Signals
    signal unlocked()
    signal authenticationFailed()

    // State properties - shared across all surfaces
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    // Clear failure message when user starts typing
    onCurrentTextChanged: {
        if (currentText.length > 0) {
            showFailure = false;
            failureTimer.stop();
        }
    }

    // Timer to auto-hide failure message after 3 seconds
    Timer {
        id: failureTimer
        interval: 3000
        repeat: false
        onTriggered: {
            root.showFailure = false;
        }
    }

    // Try to unlock with the current password
    function tryUnlock() {
        if (currentText === "" || unlockInProgress) return;
        
        unlockInProgress = true;
        showFailure = false;
        failureTimer.stop();
        pam.start();
    }

    // Clear the input field
    function clearInput() {
        currentText = "";
        showFailure = false;
        failureTimer.stop();
    }

    // Handle authentication failure
    function handleAuthFailure(errorMessage) {
        currentText = "";
        showFailure = true;
        unlockInProgress = false;
        failureTimer.start();
        authenticationFailed();
    }

    // PAM authentication context
    PamContext {
        id: pam

        // Use custom pam config in pam/password.conf
        configDirectory: Qt.resolvedUrl("../pam")
        config: "password.conf"

        // Handle PAM messages (password prompt)
        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText);
            }
        }

        // Handle authentication completion
        onCompleted: function(result) {
            if (result === PamResult.Success) {
                root.unlocked();
                root.unlockInProgress = false;
            } else {
                root.handleAuthFailure("PAM returned: " + result);
            }
        }

        // Handle errors
        onError: function(error) {
            root.handleAuthFailure("PAM error: " + error);
        }
    }
}
