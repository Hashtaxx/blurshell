pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.settings

Singleton {
    id: state
    // if lockscreen is active, hide other UI elements
    readonly property bool barVisible: true
    
    // Use previous property names for clarity and compatibility
    property bool preLockOverlayVisible: false
    property bool lockscreenVisible: false
    property bool launcherVisible: false
    property bool controlCenterVisible: false
    property bool settingsWindowVisible: false
    property bool clipHistVisible: false
    property bool isFreshStartup: true

    // Timer to delay lockscreen after overlay fade-in
    Timer {
        id: smoothLockTimer
        interval: 300  // Match fade-in duration
        repeat: false
        onTriggered: {
            lockscreenVisible = true;
        }
    }

    // Timer to delay overlay fade-out after unlock
    Timer {
        id: overlayFadeTimer
        interval: 300  // Match fade-out duration
        repeat: false
        onTriggered: {
            preLockOverlayVisible = false;
        }
    }

    // Start overlay, then show lockscreen after fade-in
    function lock() {
        preLockOverlayVisible = true;
        smoothLockTimer.start();
    }

    // Hide lockscreen, then fade out overlay
    function unlock() {
        lockscreenVisible = false;
        overlayFadeTimer.start();
    }

    function toggleLockscreen() {
        if (lockscreenVisible) {
            unlock();
        } else {
            lock();
        }
    }
    
    function toggleLauncher() {
        launcherVisible = !launcherVisible;
    }
    function toggleControlCenter() {
        controlCenterVisible = !controlCenterVisible;
    }
    function toggleSettingsWindow() {
        settingsWindowVisible = !settingsWindowVisible;
    }
    function toggleClipHist() {
        clipHistVisible = !clipHistVisible;
    }

    // Open functions
    function openLauncher() {
        launcherVisible = true;
    }
    function openControlCenter() {
        controlCenterVisible = true;
    }
    function openSettingsWindow() {
        settingsWindowVisible = true;
    }
    function openClipHist() {
        clipHistVisible = true;
    }

    // Close functions
    function closeLockscreen() {
        lockscreenVisible = false;
    }
    function closeLauncher() {
        launcherVisible = false;
    }
    function closeControlCenter() {
        controlCenterVisible = false;
    }
    function closeSettingsWindow() {
        settingsWindowVisible = false;
    }
    function closeClipHist() {
        clipHistVisible = false;
    }

    // Wallpaper root function: call the Wallpaper service so other modules or IPC can invoke it
    function nextWallpaper() {
        WallpaperService.nextWallpaper(true);
    }

    // Listen for reload signals to mark when a reload happens
    Connections {
        target: Quickshell

        function onReloadCompleted() {
            state.isFreshStartup = false;
        }

        function onReloadFailed() {
            state.isFreshStartup = false;
        }
    }

    // Helper function to check and lock on startup
    function tryLockOnStartup() {
        if (Config.lockOnStartup && state.isFreshStartup) {
            Qt.callLater(state.lock);
        }
    }

    // Lock on startup if configured
    Component.onCompleted: {
        if (Config.ready) {
            tryLockOnStartup();
        } else {
            Config.readyChanged.connect(() => Config.ready && tryLockOnStartup());
        }
    }

    IpcHandler {
        // expose this handler under the name "state" so external callers can use:
        // qs ipc call state nextWallpaper
        target: "state"

        // Launcher controls
        function toggleLauncher(): void {
            console.log("IPC: toggleLauncher called");
            state.toggleLauncher();
        }

        // Lockscreen controls - ONLY lock, never unlock externally
        function lockScreen(): void {
            console.log("IPC: lockScreen called");
            state.lock();
        }

        // Control Center controls
        function toggleControlCenter(): void {
            console.log("IPC: toggleControlCenter called");
            state.toggleControlCenter();
        }

        // Control Center controls
        function toggleClipboard(): void {
            console.log("IPC: Clipboard called");
            state.toggleClipHist();
        }

        // Wallpaper controls
        function nextWallpaper(): void {
            console.log("IPC: nextWallpaper called");
            // delegate to the root function so behavior is centralized
            state.nextWallpaper();
        }
    }
}
