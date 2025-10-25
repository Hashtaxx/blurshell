// WindowMover.qml
// Service to move windows from special workspaces to main workspace (5)
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.settings

Singleton {
    id: root

    property var _pendingActionCallback: null

    // Get the first workspace ID for the main monitor
    readonly property int targetWorkspace: {
        const mainMonitorId = Config.mainMonitorId;
        const workspaceRules = Config.workspaceRules;
        if (workspaceRules && workspaceRules[mainMonitorId] && workspaceRules[mainMonitorId].length > 0) {
            return workspaceRules[mainMonitorId][0];
        }
        return 1; // Fallback to 1 if config not available
    }

    // Process to move a window to the target workspace
    Process {
        id: moveWindowProcess
        property string windowAddress: ""
        property var pendingAction: null

        readonly property string formattedAddress: {
            const addr = windowAddress.startsWith("0x") ? windowAddress : "0x" + windowAddress;
            return addr;
        }

        command: ["hyprctl", "dispatch", "movetoworkspace", root.targetWorkspace + ",address:" + formattedAddress]

        onExited: (exitCode) => {
            if (moveWindowProcess.pendingAction) {
                moveWindowProcess.pendingAction();
                moveWindowProcess.pendingAction = null;
            }
        }
    }

    // Process to lookup window initialClass from PID
    Process {
        id: pidLookupProcess
        property int targetPid: 0
        property string foundAppId: ""

        command: ["hyprctl", "clients", "-j"]

        stdout: StdioCollector {
            id: pidLookupCollector
            onStreamFinished: {
                try {
                    const clients = JSON.parse(pidLookupCollector.text);
                    if (Array.isArray(clients)) {
                        for (let i = 0; i < clients.length; i++) {
                            if (clients[i].pid === pidLookupProcess.targetPid && clients[i].initialClass) {
                                pidLookupProcess.foundAppId = clients[i].initialClass;
                                break;
                            }
                        }
                    }
                } catch (e) {
                    // JSON parse error - continue without AppId
                }
            }
        }

        onExited: (exitCode) => {
            root.processLookupResult();
        }
    }

    /**
    * Attempts to move a window associated with a notification to the main monitor's first workspace.
    * @param notification - The Notification object
    * @param onComplete - Optional callback to invoke after move completes or immediately if no move needed
    */
    function moveWindowFromSpecial(notification, onComplete) {
        const appId = extractAppId(notification);

        if (appId === null) {
            // Async PID lookup in progress
            root._pendingActionCallback = onComplete || null;
            return;
        }

        if (!appId) {
            // No AppId found, invoke callback immediately
            if (onComplete) onComplete();
            return;
        }

        executeMove(appId, onComplete);
    }

    /**
    * Extracts AppId from notification, triggering async PID lookup if needed.
    * @returns AppId string, null if async lookup started, or empty string if lookup failed
    */
    function extractAppId(notification) {
        if (notification.hints && notification.hints["sender-pid"]) {
            try {
                const senderPid = parseInt(notification.hints["sender-pid"].toString());
                if (!isNaN(senderPid) && senderPid > 0) {
                    pidLookupProcess.targetPid = senderPid;
                    pidLookupProcess.running = true;
                    return null; // Async
                }
            } catch (e) {
                // Fall through to app name
            }
        }

        return notification.appName || "";
    }

    /**
    * Processes the result of PID lookup and moves window if found.
    * @private
    */
    function processLookupResult() {
        const appId = pidLookupProcess.foundAppId;
        pidLookupProcess.foundAppId = "";

        if (appId) {
            executeMove(appId, root._pendingActionCallback);
        } else if (root._pendingActionCallback) {
            root._pendingActionCallback();
        }

        root._pendingActionCallback = null;
    }

    /**
    * Executes the window move if window is found on special workspace.
    * @private
    */
    function executeMove(appId, onComplete) {
        if (typeof BackgroundWindows === 'undefined') {
            if (onComplete) onComplete();
            return;
        }

        const windowAddress = BackgroundWindows.getAddressOnSpecial(appId);
        if (windowAddress && windowAddress !== "0x0") {
            moveWindowProcess.windowAddress = windowAddress;
            moveWindowProcess.pendingAction = onComplete || null;
            moveWindowProcess.running = true;
        } else if (onComplete) {
            onComplete();
        }
    }
}
