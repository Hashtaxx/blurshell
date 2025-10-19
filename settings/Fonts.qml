pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import qs.settings.themes

Singleton {
    // Typography: Font sizes
    readonly property int p: 14
    readonly property int h1: 24
    readonly property int h2: 22
    readonly property int h3: 20
    readonly property int h4: 18
    readonly property int h5: 16
    readonly property int h6: 14

    readonly property string iconFont: "Symbols Nerd Font"

    // Navigation icons
    readonly property string iconChevronDown: "\uf078"
    readonly property string iconChevronLeft: "\uf053"
    readonly property string iconChevronRight: "\uf054"
    readonly property string iconChevronUp: "\uf077"
    readonly property string iconMenu: "\udb80\udf5c"

    // UI state icons
    readonly property string iconCircle: "\uf111"
    readonly property string iconCircleFilled: "\uea71"
    readonly property string iconTrue: "\uf00c"
    readonly property string iconFalse: "\uf00d"
    readonly property string iconCheckboxChecked: "\uf14a"
    readonly property string iconCheckboxUnchecked: "\uf0c8"
    readonly property string iconRadioChecked: "\uf192"
    readonly property string iconRadioUnchecked: "\uf111"

    // Control and action icons
    readonly property string iconPlus: "\uf067"
    readonly property string iconClear: "\uea81"
    readonly property string iconSearch: "\uf002"
    readonly property string iconLink: "\uf0c1"
    readonly property string iconRepeat: "\uf01e"
    readonly property string iconLock: "\uf023"
    readonly property string iconInfo: "\uf05a"
    readonly property string iconBell: "\uf0f3"
    readonly property string iconSpinner: "\uf110"

    // Media and playback icons
    readonly property string iconPlay: "\uf04b"
    readonly property string iconPause: "\uf04c"
    readonly property string iconForward: "\uf04e"
    readonly property string iconBackward: "\uf04a"
    readonly property string iconMusic: "\uf001"

    // Audio and volume icons
    readonly property string iconVolumeMute: "\ueee8"
    readonly property string iconVolumeLow: "\uf026"
    readonly property string iconVolumeMedium: "\uf027"
    readonly property string iconVolumeHigh: "\uf028"
    readonly property string iconHeadset: "\udb80\udece"
    readonly property string iconSpeaker: "\uf028"
    readonly property string iconMicrophone: "\uf130"

    // Power and system icons
    readonly property string iconPowerOff: "\uf011"
    readonly property string iconSleep: "\uf186"
    readonly property string iconReboot: "\uf021"
    readonly property string iconPowerFast: "\udb81\udcc5"
    readonly property string iconPowerMedium: "\udb83\udf85"
    readonly property string iconPowerEco: "\udb83\udf86"
    readonly property string iconBattery: "\uf240"
    readonly property string iconClock: "\uf43a"
    readonly property string iconTimer: "\uf017"

    // Network and connectivity icons
    readonly property string iconWifi: "\udb81\udda9"
    readonly property string iconWifiOff: "\udb81\uddaa"
    readonly property string iconLanOn: "\udb80\ude01"
    readonly property string iconLanOff: "\udb80\ude02"
    readonly property string iconBluetooth: "\udb80\udcaf"
    readonly property string iconBluetoothConnect: "\udb80\udcb1"
    readonly property string iconBluetoothOff: "\udb80\udcb2"

    // Display and appearance icons
    readonly property string iconLightOff: "\udb80\udf36"
    readonly property string iconLightNight: "\udb86\ude4d"
    readonly property string iconMonitor: "\udb80\udf79"
    readonly property string iconRoundedCorner: "\udb85\udcfc"
    readonly property string iconGapsOut: "\udb80\udcce"
    readonly property string iconGapsIn: "\udb80\udccb"
    readonly property string iconDimming: "\udb83\udc4a"

    // Settings and configuration icons
    readonly property string iconSettings: "\uf085"
    readonly property string iconGeneralSettings: "\ue690"
    readonly property string iconTheme: "\udb81\udd0e"
    readonly property string iconPalette: "\ue22b"
    readonly property string iconColor: "\ue22b"
    readonly property string iconEye: "\uf06e"
    readonly property string iconSpacing: "\udb81\ude1e"
    readonly property string iconLockSettings: "\udb80\udf3e"

    // File and folder icons
    readonly property string iconFolder: "\uf07b"
    readonly property string iconFolderOpen: "\uf07c"
    readonly property string iconImage: "\udb80\udeeb"

    // Device and hardware icons
    readonly property string iconPhone: "\uf10b"
    readonly property string iconComputer: "\udb80\udf22"
    readonly property string iconKeyboard: "\udb80\udf0c"
    readonly property string iconMouse: "\udb80\udf7d"

    // Application and brand icons
    readonly property string iconArch: "\udb82\udcc7"
    readonly property string iconHyprland: "\uf359"
    readonly property string iconLauncher: "\udb85\udcdf"
    readonly property string iconGithub: "\uf09b"

    // Wallpaper and visual icons
    readonly property string iconWallpaperNext: "\uf03e"
    readonly property string iconSplash: "\udb80\udd88"

    // Status and feedback icons
    readonly property string iconAllDone: "\udb82\udd95"
    
}