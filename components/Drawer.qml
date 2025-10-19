// Drawer.qml
// Configurable slide-in drawer panel for left or right side of screen
// Manages focus grabbing, keyboard input, and provides a flexible layout container
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.settings
import qs.services

PanelWindow {
    id: drawer

    // Configuration properties
    property bool isRightDrawer: false // false = left drawer, true = right drawer
    property color accentColor: Config.launcherAccent
    property int drawerWidth: 500
    property bool drawerVisible: false
    property int contentSpacing: 28
    property int contentMargins: Config.drawerMargins

    // Content container - use default property to allow children
    default property alias contentData: columnLayout.data

    // Overlay content that sits above the layout (for MouseAreas, etc.)
    property alias overlayData: overlayContainer.data

    // Internal reference to the focus scope
    property Item internalFocusScope: null

    // Flag to prevent focus grab from closing drawer during focus restoration
    property bool isRestoringFocus: false

    // Set keyboard focus mode to OnDemand to maintain focus better
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Restore focus when a popup closes while launcher is visible
    Connections {
        target: DrawerFocusManager
        function onPopupClosed() {
            if (drawer.visible) {
                drawer.restoreFocus();
            }
        }
    }
    // Method to restore focus to the drawer
    function restoreFocus() {
        isRestoringFocus = true;

        // Temporarily set keyboard focus to Exclusive to force focus, then back to OnDemand
        WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive;

        Qt.callLater(() => {
            WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand;
            // Re-enable focus grab after a small delay
            Qt.callLater(() => {
                focusGrab.active = true;
                isRestoringFocus = false;
            });
        });
    }

    // Expose visibility changed signal
    signal drawerVisibilityChanged(bool visible)
    signal closeRequested

    // Positioning
    anchors {
        top: true
        left: !isRightDrawer
        right: isRightDrawer
        bottom: true
    }

    // Sizing
    implicitWidth: drawerWidth
    color: "transparent"

    // Margins - switch based on drawer side
    margins {
        left: isRightDrawer ? 0 : Config.gapsOut
        right: isRightDrawer ? Config.gapsOut : 0
        bottom: Config.gapsOut
    }

    // Main container with keyboard handling
    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: drawer.visible

        Component.onCompleted: {
            drawer.internalFocusScope = focusScope;
        }

        // Handle Escape key
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                drawer.closeRequested();
                event.accepted = true;
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.bgBlur
            radius: Config.windowRounding
            border.width: 2
            border.color: drawer.accentColor

            // Overlay container for absolute-positioned items
            Item {
                id: overlayContainer
                anchors.fill: parent
            }

            // Content container with ColumnLayout
            ColumnLayout {
                id: columnLayout
                anchors.fill: parent
                spacing: drawer.contentSpacing
                anchors.margins: drawer.contentMargins
            }
        }
    }

    // Focus grab for auto-close when clicking outside
    HyprlandFocusGrab {
        id: focusGrab
        windows: [drawer]
        active: drawer.visible

        onCleared: {
            // Don't close the drawer if we're in the middle of restoring focus
            if (!drawer.isRestoringFocus) {
                drawer.closeRequested();
            }
        }
    }

    // Sync visibility
    visible: drawerVisible

    // Emit signal when visibility changes
    onVisibleChanged: {
        drawer.drawerVisibilityChanged(visible);
    }
}
