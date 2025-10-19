pragma Singleton
import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.settings

Singleton {
    id: root

    // ========== Configuration Properties ==========
    property bool useWallpaperDirectory: false
    property string wallpaperPath: ""
    property string wallpaperDirectory: ""
    property string currentWallpaperPath: ""
    property string nextWallpaperPath: ""
    property bool autoRotateEnabled: false
    property int autoRotateInterval: 300000
    property int transitionDuration: 800
    property bool pauseAutoRotateOnManual: true

    // ========== State Properties ==========
    property var wallpaperQueue: []
    property int currentIndex: -1
    property bool isTransitioning: false
    readonly property int queueLength: wallpaperQueue.length
    
    // ========== Screen Coordination Properties ==========
    property var readyScreens: ({})  // Object to track which screens are ready
    property int expectedScreenCount: 0
    property string pendingWallpaperPath: ""

    // ========== Signals ==========
    signal wallpaperChanged(string newPath)
    signal queueRefreshed(int newLength)
    signal allScreensReady()  // New signal when all screens are ready

    // ========== Internal Properties ==========
    property bool initialLoadComplete: false

    // ========== FolderListModel for Directory Scanning ==========
    FolderListModel {
        id: folderModel
        folder: root.useWallpaperDirectory && root.wallpaperDirectory ? Qt.resolvedUrl(root.wallpaperDirectory) : ""
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.JPG", "*.JPEG", "*.PNG"]
        showDirs: false
        showDotAndDotDot: false
        showHidden: false

        onCountChanged: {
            if (initialLoadComplete && root.useWallpaperDirectory) {
                Qt.callLater(refreshQueue);
            }
        }
    }

    // ========== Auto-Rotation Timer ==========
    Timer {
        id: autoRotateTimer
        interval: root.autoRotateInterval
        running: root.autoRotateEnabled && root.useWallpaperDirectory && root.queueLength > 1 && !root.isTransitioning
        repeat: true
        onTriggered: {
            root.nextWallpaper(false);
        }
    }

    // ========== Public Methods ==========
    function nextWallpaper(manualTrigger = false) {
        if (!useWallpaperDirectory) {
            return;
        }

        if (isTransitioning) {
            return;
        }

        if (queueLength === 0) {
            return;
        }
        
        // Prevent switching if only one image (would load same image to both layers)
        if (queueLength === 1) {
            console.log("WallpaperService: Cannot switch wallpaper with only 1 image in queue");
            return;
        }

        isTransitioning = true;

        // Move to next index
        currentIndex = (currentIndex + 1) % queueLength;

        // If we've looped back to start, regenerate queue
        if (currentIndex === 0 && queueLength > 1) {
            regenerateQueue();
        }

        // Update current wallpaper
        var newPath = wallpaperQueue[currentIndex];
        currentWallpaperPath = newPath;
        
        // Update next wallpaper path for reference
        if (queueLength > 0) {
            nextWallpaperPath = wallpaperQueue[(currentIndex + 1) % queueLength];
        }
        
        // Emit signal for display component
        wallpaperChanged(newPath);

        // Reset timer if manual trigger and configured
        if (manualTrigger && pauseAutoRotateOnManual && autoRotateEnabled) {
            autoRotateTimer.restart();
        }

        // Note: transitionTimer will be started when allScreensReady() is emitted
    }

    function previousWallpaper() {
        if (!useWallpaperDirectory) {
            return;
        }

        if (isTransitioning) {
            return;
        }

        if (queueLength === 0) {
            return;
        }
        
        // Prevent switching if only one image (would load same image to both layers)
        if (queueLength === 1) {
            console.log("WallpaperService: Cannot switch wallpaper with only 1 image in queue");
            return;
        }

        isTransitioning = true;

        // Move to previous index
        currentIndex = currentIndex - 1;
        if (currentIndex < 0) {
            currentIndex = queueLength - 1;
        }

        // Update current wallpaper
        var newPath = wallpaperQueue[currentIndex];
        currentWallpaperPath = newPath;
        
        // Update next wallpaper path for reference
        if (queueLength > 0) {
            nextWallpaperPath = wallpaperQueue[(currentIndex + 1) % queueLength];
        }
        
        // Emit signal
        wallpaperChanged(newPath);

        // Note: transitionTimer will be started when allScreensReady() is emitted
    }

    function refreshQueue() {
        buildQueue();
    }

    function setWallpaper(path) {
        if (!path) {
            return;
        }
        
        // Find index in current queue
        var idx = wallpaperQueue.indexOf(path);
        
        if (idx !== -1) {
            currentIndex = idx;
            currentWallpaperPath = path;
            wallpaperChanged(path);
            
            // Update next wallpaper path for reference
            if (queueLength > 0) {
                nextWallpaperPath = wallpaperQueue[(currentIndex + 1) % queueLength];
            }
        } else {
            // Path not in queue, add it and use it
            wallpaperQueue.push(path);
            currentIndex = wallpaperQueue.length - 1;
            currentWallpaperPath = path;
            wallpaperChanged(path);
            
            // Update next wallpaper path for reference
            if (queueLength > 0) {
                nextWallpaperPath = wallpaperQueue[(currentIndex + 1) % queueLength];
            }
        }
    }
    
    // ========== Screen Coordination Methods ==========
    function registerScreen(screenName) {
        expectedScreenCount++;
    }
    
    function reportScreenReady(screenName) {
        readyScreens[screenName] = true;
        
        // Check if all screens are ready
        var readyCount = 0;
        for (var screen in readyScreens) {
            if (readyScreens[screen]) {
                readyCount++;
            }
        }
        
        if (readyCount === expectedScreenCount) {
            allScreensReady();
            readyScreens = {}; // Reset for next transition
            
            // Start the transition timer now that the visual transition is beginning
            if (isTransitioning) {
                transitionTimer.restart();
            }
        }
    }

    // ========== Internal Methods ==========
    function buildQueue() {
        // If not using directory mode, use single wallpaper path
        if (!useWallpaperDirectory) {
            if (root.wallpaperPath) {
                // Store the plain path without file:// prefix
                // The consumer (e.g., BlurredWallpaper.qml) will add file:// when needed
                var wallpaperUrl = root.wallpaperPath;
                // Remove file:// prefix if present
                if (wallpaperUrl.startsWith("file://")) {
                    wallpaperUrl = wallpaperUrl.substring(7);
                }
                wallpaperQueue = [wallpaperUrl];
                currentIndex = 0;
                currentWallpaperPath = wallpaperQueue[0];
                queueRefreshed(1);
                
                if (initialLoadComplete) {
                    wallpaperChanged(currentWallpaperPath);
                }
            } else {
                wallpaperQueue = [];
                currentIndex = -1;
                currentWallpaperPath = "";
                queueRefreshed(0);
            }
            return;
        }

        // Directory mode: build queue from folder
        var newQueue = [];
        for (var i = 0; i < folderModel.count; i++) {
            var filePath = folderModel.get(i, "filePath");
            if (filePath) {
                // filePath is a URL from FolderListModel, convert to plain path
                var pathStr = filePath.toString();
                // Remove file:// prefix to store as plain path
                if (pathStr.startsWith("file://")) {
                    pathStr = pathStr.substring(7);
                }
                newQueue.push(pathStr);
            }
        }

        if (newQueue.length === 0) {
            wallpaperQueue = [];
            currentIndex = -1;
            currentWallpaperPath = "";
            queueRefreshed(0);
            return;
        }

        // Shuffle the queue
        shuffleArray(newQueue);

        // Try to preserve current wallpaper position if it still exists
        var currentPath = currentWallpaperPath;
        wallpaperQueue = newQueue;

        if (currentPath && newQueue.indexOf(currentPath) !== -1) {
            currentIndex = newQueue.indexOf(currentPath);
        } else {
            // Start at random position (not first)
            if (newQueue.length > 1) {
                currentIndex = Math.floor(Math.random() * newQueue.length);
            } else {
                currentIndex = 0;
            }
            currentWallpaperPath = wallpaperQueue[currentIndex];
            
            // Emit signal for new wallpaper if service is initialized
            if (initialLoadComplete) {
                wallpaperChanged(currentWallpaperPath);
            }
        }

        queueRefreshed(wallpaperQueue.length);

        // Update next wallpaper path for reference
        if (queueLength > 0) {
            nextWallpaperPath = wallpaperQueue[(currentIndex + 1) % queueLength];
        }
    }

    function regenerateQueue() {
        var oldQueue = wallpaperQueue.slice(); // Copy current queue
        shuffleArray(wallpaperQueue);
        
        // Ensure new queue doesn't start with the same image we just showed
        if (wallpaperQueue.length > 1 && wallpaperQueue[0] === oldQueue[oldQueue.length - 1]) {
            // Swap first and last
            var temp = wallpaperQueue[0];
            wallpaperQueue[0] = wallpaperQueue[wallpaperQueue.length - 1];
            wallpaperQueue[wallpaperQueue.length - 1] = temp;
        }
    }

    function shuffleArray(array) {
        // Fisher-Yates shuffle
        for (var i = array.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1));
            var temp = array[i];
            array[i] = array[j];
            array[j] = temp;
        }
    }

    // ========== Transition Timer ==========
    Timer {
        id: transitionTimer
        interval: root.transitionDuration
        onTriggered: {
            root.isTransitioning = false;
        }
    }

    // ========== Config Change Handlers ==========
    Connections {
        target: Config

        function onUseWallpaperDirectoryChanged() {
            root.useWallpaperDirectory = Config.useWallpaperDirectory;
            Qt.callLater(refreshQueue);
        }

        function onWallpaperPathChanged() {
            root.wallpaperPath = Config.wallpaperPath;
            if (!root.useWallpaperDirectory) {
                Qt.callLater(refreshQueue);
            }
        }

        function onAutoRotateEnabledChanged() {
            root.autoRotateEnabled = Config.autoRotateEnabled;
        }

        function onAutoRotateIntervalChanged() {
            root.autoRotateInterval = Config.autoRotateInterval;
            if (autoRotateTimer.running) {
                autoRotateTimer.restart();
            }
        }

        function onWallpaperDirectoryChanged() {
            root.wallpaperDirectory = Config.wallpaperDirectory;
            if (root.useWallpaperDirectory) {
                Qt.callLater(refreshQueue);
            }
        }
    }

    // ========== Initialization ==========
    Component.onCompleted: {
        // Wait for Config to be ready before initializing
        if (Config.ready) {
            initializeService();
        }
    }

    Connections {
        target: Config
        
        function onReadyChanged() {
            if (Config.ready && !initialLoadComplete) {
                initializeService();
            }
        }
    }

    function initializeService() {
        // Load config values
        root.useWallpaperDirectory = Config.useWallpaperDirectory;
        root.wallpaperPath = Config.wallpaperPath;
        root.wallpaperDirectory = Config.wallpaperDirectory;
        root.autoRotateEnabled = Config.autoRotateEnabled;
        root.autoRotateInterval = Config.autoRotateInterval;
        root.pauseAutoRotateOnManual = Config.pauseAutoRotateOnManual;
        
        // Build initial queue
        buildQueue();
        initialLoadComplete = true;
        
        // Emit initial wallpaper after queue is built
        if (currentWallpaperPath) {
            wallpaperChanged(currentWallpaperPath);
        }
    }
}
