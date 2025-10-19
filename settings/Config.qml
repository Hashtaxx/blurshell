pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.settings

Singleton {
    id: root
    property string filePath: Qt.resolvedUrl("./config.json")
    property bool ready: false

    // For writing to the config file
    property alias set: configJsonAdapter

    // Easy access to config properties with Config.aliasName
    readonly property alias audioIncrement: configJsonAdapter.audioIncrement
    readonly property alias autoRotateEnabled: configJsonAdapter.autoRotateEnabled
    readonly property alias autoRotateInterval: configJsonAdapter.autoRotateInterval
    readonly property alias barHeight: configJsonAdapter.barHeight
    readonly property alias clipHistWidth: configJsonAdapter.clipHistWidth
    readonly property alias controlCenterWidth: configJsonAdapter.controlCenterWidth
    readonly property alias defaultExpireTimeout: configJsonAdapter.defaultExpireTimeout
    readonly property alias excludedExtensions: configJsonAdapter.excludedExtensions
    readonly property string fileSearchPath: root.expandPath(configJsonAdapter.fileSearchPath)
    readonly property alias gapsIn: configJsonAdapter.gapsIn
    readonly property alias gapsOut: configJsonAdapter.gapsOut
    readonly property alias includeHiddenFiles: configJsonAdapter.includeHiddenFiles
    readonly property alias launcherWidth: configJsonAdapter.launcherWidth
    readonly property alias drawerMargins: configJsonAdapter.drawerMargins
    readonly property alias lockOnStartup: configJsonAdapter.lockOnStartup
    readonly property alias lockscreenDimming: configJsonAdapter.lockscreenDimming
    readonly property alias mainMonitorId: configJsonAdapter.mainMonitorId
    readonly property alias pauseAutoRotateOnManual: configJsonAdapter.pauseAutoRotateOnManual
    readonly property alias settingsHeight: configJsonAdapter.settingsHeight
    readonly property alias showSplashOnLockscreen: configJsonAdapter.showSplashOnLockscreen
    readonly property alias showSplashOnWallpaper: configJsonAdapter.showSplashOnWallpaper
    readonly property alias showVolumeBarAlways: configJsonAdapter.showVolumeBarAlways
    readonly property alias theme: configJsonAdapter.theme
    readonly property alias transparency: configJsonAdapter.transparency
    readonly property alias useDebounceTimer: configJsonAdapter.useDebounceTimer
    readonly property alias useWallpaperDirectory: configJsonAdapter.useWallpaperDirectory
    readonly property string wallpaperDirectory: root.expandPath(configJsonAdapter.wallpaperDirectory)
    readonly property string wallpaperPath: root.expandPath(configJsonAdapter.wallpaperPath)
    readonly property alias windowRounding: configJsonAdapter.windowRounding
    readonly property alias workspaceRules: configJsonAdapter.workspaceRules

    // Settable colors
    readonly property color launcherAccent: root.resolveColor(configJsonAdapter.launcherAccent)
    readonly property color launcherBackground: root.resolveColor(configJsonAdapter.launcherBackground)
    readonly property color controlCenterAccent: root.resolveColor(configJsonAdapter.controlCenterAccent)
    readonly property color controlCenterBackground: root.resolveColor(configJsonAdapter.controlCenterBackground)
    readonly property color clipHistAccent: root.resolveColor(configJsonAdapter.clipHistAccent)
    readonly property color clipHistBackground: root.resolveColor(configJsonAdapter.clipHistBackground)
    
    // Helper function to expand ~ to home directory (for reading)
    function expandPath(path) {
        if (!path) return "";
        
        // Expand ~ to home directory
        if (path.startsWith("~/")) {
            var homeDir = Quickshell.env("HOME");
            return homeDir + path.substring(1);
        }
        return path;
    }
    
    // Helper function to collapse home directory to ~ (for writing)
    function collapsePath(path) {
        if (!path) return "";
        
        var homeDir = Quickshell.env("HOME");
        if (path.startsWith(homeDir + "/")) {
            return "~" + path.substring(homeDir.length);
        }
        return path;
    }
    
    function resolveColor(name) {
        switch (name) {
            case "rosewater": return Colors.rosewater;
            case "flamingo": return Colors.flamingo;
            case "pink": return Colors.pink;
            case "mauve": return Colors.mauve;
            case "red": return Colors.red;
            case "maroon": return Colors.maroon;
            case "peach": return Colors.peach;
            case "yellow": return Colors.yellow;
            case "green": return Colors.green;
            case "teal": return Colors.teal;
            case "sky": return Colors.sky;
            case "sapphire": return Colors.sapphire;
            case "blue": return Colors.blue;
            case "lavender": return Colors.lavender;
            case "crust": return Colors.textSecondary;
            case "base": return Colors.bg;
            case "mantle": return Colors.bgDark;
            default: return Colors.text;
        }
    }

    FileView {
        path: root.filePath
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                writeAdapter();
            }
        }

        JsonAdapter {
            id: configJsonAdapter

            // ============================================================
            // Global Spacings & Appearance
            // ============================================================
            property int gapsOut: 12
            property int gapsIn: 4
            property int windowRounding: 12
            property int drawerMargins: 28
            property string mainMonitorId: "DP-1"
            property var workspaceRules: ({})
            
            // Theme & Colors
            property string theme: "CatppuccinMocha"
            property real transparency: 0.77

            // ============================================================
            // Bar
            // ============================================================
            property int barHeight: 44
            property real audioIncrement: 2
            property bool showVolumeBarAlways: true  // Set to false to only show when volume changes

            // ============================================================
            // SettingsWindow
            // ============================================================
            property int settingsHeight: 44

            // ============================================================
            // Launcher
            // ============================================================
            property int launcherWidth: 600
            property string fileSearchPath: "/home/kai"
            property bool includeHiddenFiles: false
            property var excludedExtensions: [".log", ".tmp", ".cache", ".ini", ".pid", ".lock", ".sock"]
            property bool useDebounceTimer: false
            
            // Colors
            property string launcherAccent: "lavender"
            property string launcherBackground: "mantle"

            // ============================================================
            // ClipHistory
            // ============================================================
            property int clipHistWidth: controlCenterWidth
            
            // Colors
            property string clipHistAccent: "green"
            property string clipHistBackground: "mantle"

            // ============================================================
            // ControlCenter
            // ============================================================
            property int controlCenterWidth: 450
            
            // Colors
            property string controlCenterAccent: "maroon"
            property string controlCenterBackground: "mantle"

            // ============================================================
            // LockscreenOverlay & Lock
            // ============================================================
            property bool lockOnStartup: false  // Set to true to automatically lock on Quickshell startup
            property real lockscreenDimming: 0.4  // Dimming opacity for lockscreen overlay (0.0 - 1.0)
            
            // Splash
            property bool showSplashOnLockscreen: true

            // ============================================================
            // Wallpaper
            // ============================================================
            property string wallpaperPath: ""
            property string wallpaperDirectory: "~/Pictures/Wallpapers"
            property bool useWallpaperDirectory: false
            
            // Auto-rotation settings
            property bool autoRotateEnabled: false
            property int autoRotateInterval: 1800000 // 60min in milliseconds
            property bool pauseAutoRotateOnManual: true

            // Splash
            property bool showSplashOnWallpaper: false

            // ============================================================
            // NotificationPopup
            // ============================================================
            property int defaultExpireTimeout: 5000

            // ============================================================
            // ReloadPopup
            // ============================================================
            // (No specific settings yet)
        }
    }

    // (Removed backwards-compatibility aliases) Use `root.options` or `configJsonAdapter` directly.

}
