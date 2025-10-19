pragma Singleton
import Quickshell


// Somehow the Drawer looses Focus, whenever a Popup like RelaodPopup or a Notification disappears and I have no clue how to fix this. I opted for just retriggering Focus whenever a popup get's closed. Whoever fixes this and can me explain how, you get a coffee!
Singleton {
    id: focusManager

    // Signal emitted when a popup window is closed/destroyed
    signal popupClosed()

    // Call this when any PanelWindow could close while a Drawer with a searchbar is open
    function notifyPopupClosed() {
        popupClosed()
    }
}
