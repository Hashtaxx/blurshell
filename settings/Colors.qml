pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import QtQuick
import qs.settings
import qs.settings.themes

Singleton {
    // Maps the string from Config to an imported Theme singleton
    readonly property QtObject theme: resolveTheme(Config.theme)
    function resolveTheme(name) {
        switch (name) {
        case "CatppuccinMocha": return CatppuccinMocha;
        case "CatppuccinLatte": return CatppuccinLatte;
        case "CatppuccinFrappe": return CatppuccinFrappe;
        case "CatppuccinMacchiato": return CatppuccinMacchiato;
        default: return CatppuccinMocha;  // Fallback to Mocha theme
        }
    }

    // Theme colors
    readonly property color rosewater: theme.rosewater
    readonly property color flamingo: theme.flamingo
    readonly property color pink: theme.pink
    readonly property color mauve: theme.mauve
    readonly property color red: theme.red
    readonly property color maroon: theme.maroon
    readonly property color peach: theme.peach
    readonly property color yellow: theme.yellow
    readonly property color green: theme.green
    readonly property color teal: theme.teal
    readonly property color sky: theme.sky
    readonly property color sapphire: theme.sapphire
    readonly property color blue: theme.blue
    readonly property color lavender: theme.lavender

    // Background colors
    readonly property color text: theme.text
    readonly property color textSecondary: theme.crust
    readonly property color textSubdued: theme.subtext0

    readonly property color bg: theme.base
    readonly property color bg_1: theme.surface1
    readonly property color bg_2: theme.surface2
    readonly property color bg_4: theme.overlay2
    readonly property color bgDark: theme.mantle

    readonly property color bgBlur: Qt.alpha(theme.base, Config.transparency)
    readonly property color bg_1Blur: Qt.alpha(theme.surface1, Config.transparency)
    readonly property color bg_2Blur: Qt.alpha(theme.surface2, Config.transparency)
    readonly property color bg_3Blur: Qt.alpha(theme.overlay0, Config.transparency)
    readonly property color bg_4Blur: Qt.alpha(theme.overlay2, Config.transparency)    
    readonly property color bgDarkBlur: Qt.alpha(theme.mantle, Config.transparency)

    // Brightness modifier (flipped for light themes)
    readonly property bool isLightTheme: Config.theme === "CatppuccinLatte"
    
    readonly property color brighten_1: isLightTheme ? Qt.rgba(0, 0, 0, 0.01) : Qt.rgba(1, 1, 1, 0.01)
    readonly property color brighten_3: isLightTheme ? Qt.rgba(0, 0, 0, 0.03) : Qt.rgba(1, 1, 1, 0.03)
    readonly property color brighten_5: isLightTheme ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.05)
    readonly property color brighten_10: isLightTheme ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(1, 1, 1, 0.1)
    readonly property color brighten_20: isLightTheme ? Qt.rgba(0, 0, 0, 0.2) : Qt.rgba(1, 1, 1, 0.2)
    readonly property color brighten_50: isLightTheme ? Qt.rgba(0, 0, 0, 0.5) : Qt.rgba(1, 1, 1, 0.5)

    readonly property color darken_1: isLightTheme ? Qt.rgba(1, 1, 1, 0.01) : Qt.rgba(0, 0, 0, 0.01)
    readonly property color darken_3: isLightTheme ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0, 0, 0, 0.03)
    readonly property color darken_5: isLightTheme ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.05)
    readonly property color darken_10: isLightTheme ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.1)
    readonly property color darken_20: isLightTheme ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(0, 0, 0, 0.2)
    readonly property color darken_50: isLightTheme ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.5)

}