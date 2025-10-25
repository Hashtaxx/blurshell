pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.settings
import qs.services
import qs.components
import qs.components.animations

/**
 * SystemTray - Displays system tray icons and background workspace windows
 * 
 * Features:
 * - Regular system tray items with left-click activation, right-click menu
 * - Background workspace windows (workspace -98) with window management actions
 * - Uses TrayIcon component for consistent icon rendering
 * - Automatically hides when both tray and background windows are empty
 */

Background {
    id: root

    visible: trayRepeater.count > 0 || backgroundWindowsRepeater.count > 0

    // === BACKGROUND WINDOWS DATA ===

    property var backgroundWindowsList: []

    function updateBackgroundWindows() {
        const appIds = BackgroundWindows.getAppIdsOnSpecial();
        const windows = [];

        for (let i = 0; i < appIds.length; i++) {
            const appId = appIds[i];
            const windowData = BackgroundWindows.getWindowsByAppId(appId);
            
            // Add all windows for this app, not just the first one
            for (let j = 0; j < windowData.length; j++) {
                const window = windowData[j];
                // Only include if on special workspace
                if (window.workspaceName && window.workspaceName.includes("special")) {
                    windows.push({
                        address: window.address,
                        title: window.title,
                        iconName: BackgroundWindows.getIconForAppId(appId),
                        appId: appId
                    });
                }
            }
        }

        // Create a new array to ensure Qt recognizes the change
        root.backgroundWindowsList = [...windows];
    }

    Connections {
        target: BackgroundWindows
        function onWorkspacesRefreshed() {
            root.updateBackgroundWindows();
        }
    }

    Component.onCompleted: {
        root.updateBackgroundWindows();
    }

    // === LAYOUT ===

    Row {
        id: trayRow
        spacing: Config.gapsIn
        height: parent.height
        anchors.centerIn: parent

        // === BACKGROUND WINDOWS ===

        Repeater {
            id: backgroundWindowsRepeater
            model: root.backgroundWindowsList

            delegate: Item {
                id: windowItem
                required property var modelData

                width: parent ? parent.height : 32
                height: parent ? parent.height : 32

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: function (mouse) {
                        if (mouse.button === Qt.RightButton) {
                            // Right-click: Open menu
                            windowActionPopup.windowAddress = windowItem.modelData.address;
                            windowActionPopup.windowTitle = windowItem.modelData.title;
                            windowActionPopup.windowClass = windowItem.modelData.iconName;
                            windowActionPopup.anchorItem = windowItem;
                            windowActionPopup.open();
                        } else {
                            // Left-click: Open window directly
                            windowActionPopup.windowAddress = windowItem.modelData.address;
                            windowActionPopup.openWindow();
                        }
                    }

                    TrayIcon {
                        anchors.fill: parent
                        iconName: windowItem.modelData.iconName
                        isHovered: mouseArea.containsMouse
                    }
                }
            }
        }

        // === SYSTEM TRAY ITEMS ===

        Repeater {
            id: trayRepeater
            model: SystemTray.items

            delegate: Item {
                id: trayItem
                required property var modelData

                width: parent ? parent.height : 32
                height: parent ? parent.height : 32

                MouseArea {
                    id: trayMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: function (mouse) {
                        if (mouse.button === Qt.RightButton) {
                            qsMenu.menu = trayItem.modelData.menu;
                            qsMenu.anchorItem = trayItem;
                            qsMenu.open();
                        } else {
                            trayItem.modelData.activate();
                        }
                    }

                    Image {
                        id: trayIconImage
                        anchors.centerIn: parent
                        width: parent.width * 0.9
                        height: parent.height * 0.9
                        source: trayItem.modelData.icon
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        scale: trayMouseArea.containsMouse ? 1 : 0.9
                        AnimatedScale on scale {}
                    }
                }
            }
        }
    }

    // === POPUPS ===

    QsMenu {
        id: qsMenu
    }

    WindowActionPopup {
        id: windowActionPopup
    }
}
