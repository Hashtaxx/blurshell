// Utility functions for notifications

/**
 * Converts a timestamp to a human-readable relative time string
 * @param {number} timestamp - Unix timestamp in milliseconds
 * @returns {string} Formatted time string (e.g., "5 mins ago", "Just now", "1 day ago")
 */
function getFriendlyNotifTimeString(timestamp) {
    const now = Date.now();
    const diff = now - timestamp;
    
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    
    if (seconds < 60) {
        return "Just now";
    } else if (minutes < 60) {
        return minutes === 1 ? "1 min ago" : `${minutes} mins ago`;
    } else if (hours < 24) {
        return hours === 1 ? "1 hour ago" : `${hours} hours ago`;
    } else if (days < 7) {
        return days === 1 ? "1 day ago" : `${days} days ago`;
    } else {
        // Format as date
        const date = new Date(timestamp);
        return date.toLocaleDateString();
    }
}

/**
 * Processes and cleans notification body text
 * Removes extraneous content from Chromium-based browser notifications
 * @param {string} body - The raw notification body text
 * @param {string} appName - The name of the application sending the notification
 * @returns {string} Processed body text with unwanted content removed
 */
function processNotificationBody(body, appName) {
    if (!body) return ""
    let processedBody = body

    // Clean Chromium-based browsers notifications - remove first line
    if (appName) {
        const appNameStr = String(appName)
        const lowerApp = appNameStr.toLowerCase()
        const chromiumBrowsers = [
            "brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"
        ]

        if (chromiumBrowsers.some(name => lowerApp.includes(name))) {
            const lines = body.split('\n\n')

            if (lines.length > 1 && lines[0].startsWith('<a')) {
                processedBody = lines.slice(1).join('\n\n')
            }
        }
    }

    return processedBody
}