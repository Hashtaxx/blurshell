pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // System information properties
    property string hostname: ""
    property string osRelease: ""
    property string kernelVersion: ""
    property int uptimeDays: 0
    property int uptimeHours: 0
    property int uptimeMinutes: 0
    
    // Get hostname
    Process {
        id: hostnameProc
        command: ["hostname"]
        running: true
        
        stdout: StdioCollector {
            onStreamFinished: {
                root.hostname = text.trim()
            }
        }
    }
    
    // Get OS release information
    Process {
        id: osReleaseProc
        command: ["sh", "-c", "cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"'"]
        running: true
        
        stdout: StdioCollector {
            onStreamFinished: {
                root.osRelease = text.trim()
            }
        }
    }
    
    // Get kernel version
    Process {
        id: kernelProc
        command: ["uname", "-r"]
        running: true
        
        stdout: StdioCollector {
            onStreamFinished: {
                root.kernelVersion = text.trim()
            }
        }
    }
    
    // Get uptime (in seconds from /proc/uptime)
    Process {
        id: uptimeProc
        command: ["sh", "-c", "cat /proc/uptime | awk '{print int($1)}'"]
        running: true
        
        stdout: StdioCollector {
            onStreamFinished: {
                var totalSeconds = parseInt(text.trim())
                root.uptimeDays = Math.floor(totalSeconds / 86400)
                root.uptimeHours = Math.floor((totalSeconds % 86400) / 3600)
                root.uptimeMinutes = Math.floor((totalSeconds % 3600) / 60)
            }
        }
    }
    
    // Timer to refresh uptime
    Timer {
        interval: 60000 // Update every minute
        running: true
        repeat: true
        
        onTriggered: {
            uptimeProc.running = true
        }
    }
}
