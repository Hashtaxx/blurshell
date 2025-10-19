// Mainscreen.qml
// Variants wrapper that targets the main monitor or uses all screens as fallback
pragma ComponentBehavior: Bound
import Quickshell
import qs.settings

Variants {
    id: launcherVariants
    model: {
        const s = Quickshell.screens.find(scr => scr.name === Config.mainMonitorId);
        if (s)
            return [s];
        const active = Quickshell.screens.find(scr => scr === Quickshell.activeScreen);
        return active ? [active] : Quickshell.screens;
    }
}
