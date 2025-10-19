pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.lockscreen.components
import qs.settings

ShellRoot {
    id: lockRoot
    reloadableId: "lockscreenModule"

    // Create lock context to manage state across all screens
    LockContext {
        id: lockContext

        onUnlocked: {
            // Unlock the session before closing
            sessionLock.locked = false;
            // Close the lockscreen with smooth animation
            AppState.unlock();
        }
    }

    // Session lock - creates surfaces for all screens
    WlSessionLock {
        id: sessionLock
        locked: AppState.lockscreenVisible

        WlSessionLockSurface {
            id: lockSurface
            color: "transparent"
            
            Surface {
                anchors.fill: parent
                context: lockContext
                screenInfo: lockSurface.screen
            }
        }
    }
}
