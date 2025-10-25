// BackgroundWindows.qml
// Service to track windows on the special background workspace (-98)
pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    // Special workspace ID for background windows
    readonly property int specialWorkspaceId: -98

    // Workspaces data structure
    property var workspaces: ({})
    property int updateTrigger: 0

    // Signal emitted when workspaces data is refreshed
    signal workspacesRefreshed()

    // Get icon for appId by matching against DesktopEntry.id (case-insensitive)
    function getIconForAppId(appId) {
        if (!appId || !DesktopEntries || !DesktopEntries.applications || !DesktopEntries.applications.values) {
            return "";
        }

        const appIdLower = appId.toLowerCase();
        const entries = DesktopEntries.applications.values;

        for (let i = 0; i < entries.length; i++) {
            const entry = entries[i];
            if (entry.id && entry.id.toLowerCase() === appIdLower) {
                return entry.icon || "";
            }
        }

        return "";
    }

    // Refresh workspaces structure
    function refreshWorkspacesData() {
        const newWorkspaces = {};
        const wsValues = Hyprland.workspaces.values || [];

        for (let i = 0; i < wsValues.length; i++) {
            const ws = wsValues[i];
            const toplevelsArray = [];
            const tlValues = ws.toplevels.values || [];

            for (let j = 0; j < tlValues.length; j++) {
                const tl = tlValues[j];
                const appId = tl.wayland ? tl.wayland.appId : "";
                const icon = getIconForAppId(appId);
                
                toplevelsArray.push({
                    address: tl.address,
                    title: tl.title,
                    waylandAppId: appId,
                    icon: icon
                });
            }

            newWorkspaces[ws.name] = {
                id: ws.id,
                name: ws.name,
                toplevels: toplevelsArray
            };
        }

        root.workspaces = newWorkspaces;
        root.updateTrigger++;
        root.workspacesRefreshed();
    }

    // Get window address by appId (searches all workspaces)
    function getAddress(appId) {
        for (const wsId in root.workspaces) {
            const ws = root.workspaces[wsId];
            for (let i = 0; i < ws.toplevels.length; i++) {
                const tl = ws.toplevels[i];
                if (tl.waylandAppId === appId) {
                    return tl.address;
                }
            }
        }
        return null;
    }

    // Get window address by appId on special workspaces only
    function getAddressOnSpecial(appId) {
        for (const wsName in root.workspaces) {
            // Only search workspaces with "special" in the name
            if (wsName.includes("special")) {
                const ws = root.workspaces[wsName];
                for (let i = 0; i < ws.toplevels.length; i++) {
                    const tl = ws.toplevels[i];
                    if (tl.waylandAppId === appId) {
                        return tl.address;
                    }
                }
            }
        }
        return null;
    }

    // Get all windows with appId (across all workspaces)
    function getWindowsByAppId(appId) {
        const windows = [];
        for (const wsId in root.workspaces) {
            const ws = root.workspaces[wsId];
            for (let i = 0; i < ws.toplevels.length; i++) {
                const tl = ws.toplevels[i];
                if (tl.waylandAppId.toLowerCase() === appId.toLowerCase()) {
                    windows.push({
                        address: tl.address,
                        title: tl.title,
                        waylandAppId: tl.waylandAppId,
                        icon: tl.icon,
                        workspaceId: wsId,
                        workspaceName: ws.name
                    });
                }
            }
        }
        return windows;
    }

    // Get all appIds on a specific workspace
    function getAppIdsByWorkspace(workspaceName) {
        const ws = root.workspaces[workspaceName];
        if (!ws) return false;

        const appIds = [];
        for (let i = 0; i < ws.toplevels.length; i++) {
            const tl = ws.toplevels[i];
            if (tl.waylandAppId && !appIds.includes(tl.waylandAppId)) {
                appIds.push(tl.waylandAppId);
            }
        }
        return appIds;
    }

    // Get all appIds from special workspaces
    function getAppIdsOnSpecial() {
        const appIds = [];
        for (const wsName in root.workspaces) {
            // Only search workspaces with "special" in the name
            if (wsName.includes("special")) {
                const ws = root.workspaces[wsName];
                for (let i = 0; i < ws.toplevels.length; i++) {
                    const tl = ws.toplevels[i];
                    if (tl.waylandAppId && !appIds.includes(tl.waylandAppId)) {
                        appIds.push(tl.waylandAppId);
                    }
                }
            }
        }
        return appIds;
    }

    // Listen to Hyprland events
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const n = event.name;
            const baseName = n.replace(/v2$/, "");
            if (["openwindow", "closewindow", "movewindow", "activespecial"].includes(baseName)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshToplevels();
                root.refreshWorkspacesData();
            }
        }
    }

    // Initial load
    Component.onCompleted: {
        root.refreshWorkspacesData();
    }
}
