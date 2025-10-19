pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.settings

Singleton {
    id: root

    property string currentQuery: ""
    property var searchResults: []
    property bool isSearching: false
    property bool hasPerformedSearch: false  // Tracks if any search/listing has completed
    property int maxResults: 100
    property int operationId: 0  // Track which operation is current
    property int lastCompletedOperationId: -1  // Track last completed operation to prevent duplicates

    signal resultsReady()

    // Sort function: directories first, then by name (case-insensitive)
    function sortResults(results) {
        return results.sort((a, b) => {
            // Directories come before files
            if (a.isDirectory !== b.isDirectory) {
                return a.isDirectory ? -1 : 1;
            }
            // Within same type, sort alphabetically (case-insensitive)
            return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
        });
    }

    // Debounce timer to avoid too many searches
    property Timer searchTimer: Timer {
        id: searchTimer
        interval: 300
        repeat: false
        onTriggered: root.performSearch()
    }

    // Search process
    property Process searchProcess: Process {
        id: searchProcess
        running: false
        property int myOperationId: 0  // Track which operation started this process

        stdout: StdioCollector {
            id: searchCollector
            onStreamFinished: {
                // Only process results if this is still the current operation
                if (searchProcess.myOperationId !== root.operationId) {
                    return;
                }
                
                // Prevent processing the same operation twice
                if (searchProcess.myOperationId === root.lastCompletedOperationId) {
                    return;
                }
                
                root.lastCompletedOperationId = searchProcess.myOperationId;
                root.isSearching = false;
                root.hasPerformedSearch = true;
                const lines = text.trim().split('\n').filter(line => line.length > 0);
                
                // Parse results into file objects
                const parsedResults = lines.slice(0, root.maxResults).map(path => {
                    const cleanPath = path.replace(/\/$/, ''); // Remove trailing slash
                    const parts = cleanPath.split('/');
                    const name = parts[parts.length - 1];
                    const isDirectory = path.endsWith('/'); // fd marks directories with /
                    
                    return {
                        path: cleanPath,
                        name: name || '/', // If name is empty, it's root directory
                        isDirectory: isDirectory,
                        parentPath: parts.slice(0, -1).join('/')
                    };
                });
                
                // Sort: directories first, then by name
                root.searchResults = root.sortResults(parsedResults);
                root.resultsReady();
            }
        }

        stderr: StdioCollector {
            id: errorCollector
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("FileSearch error:", text);
                }
            }
        }
    }

    // Directory listing process (for showing initial directory contents)
    property Process listProcess: Process {
        id: listProcess
        running: false
        property int myOperationId: 0  // Track which operation started this process

        stdout: StdioCollector {
            id: listCollector
            onStreamFinished: {
                // Only process results if this is still the current operation
                if (listProcess.myOperationId !== root.operationId) {
                    return;
                }
                
                // Prevent processing the same operation twice
                if (listProcess.myOperationId === root.lastCompletedOperationId) {
                    return;
                }
                
                root.lastCompletedOperationId = listProcess.myOperationId;
                root.isSearching = false;
                root.hasPerformedSearch = true;
                const lines = text.trim().split('\n').filter(line => line.length > 0);
                
                // Parse results into file objects (same format as search)
                const parsedResults = lines.map(path => {
                    const cleanPath = path.replace(/\/$/, '');
                    const parts = cleanPath.split('/');
                    const name = parts[parts.length - 1];
                    const isDirectory = path.endsWith('/');
                    
                    return {
                        path: cleanPath,
                        name: name || '/',
                        isDirectory: isDirectory,
                        parentPath: parts.slice(0, -1).join('/')
                    };
                });
                
                // Sort: directories first, then by name
                root.searchResults = root.sortResults(parsedResults);
                root.resultsReady();
            }
        }

        stderr: StdioCollector {
            id: listErrorCollector
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("FileSearch list error:", text);
                }
            }
        }
    }

    function search(query) {
        root.currentQuery = query;
        
        if (root.currentQuery.length === 0) {
            // Show directory contents instead of empty results
            listDirectory(Config.fileSearchPath);
            return;
        }

        // Execute immediately if debounce is disabled, otherwise use timer
        if (Config.useDebounceTimer) {
            searchTimer.restart();
        } else {
            performSearch();
        }
    }

    function expandTildePath(path) {
        if (!path) return "";
        if (path.startsWith("~/")) {
            const homeDir = Quickshell.env("HOME");
            return homeDir + path.substring(1);
        }
        if (path === "~") {
            return Quickshell.env("HOME");
        }
        return path;
    }

    function performSearch() {
        if (root.currentQuery.length === 0) {
            return;
        }

        // Increment operation ID to invalidate any previous operations
        root.operationId++;
        
        // Stop any running searches or listings
        if (searchProcess.running) {
            searchProcess.running = false;
        }
        if (listProcess.running) {
            listProcess.running = false;
        }

        root.isSearching = true;
        root.hasPerformedSearch = false;  // Reset until results are ready

        // Build fd command with config options
        let cmd = ["fd"];
        
        // Add query pattern
        cmd.push(root.currentQuery);
        
        // Add search path (ensure ~ is expanded)
        const searchPath = root.expandTildePath(Config.fileSearchPath);
        cmd.push(searchPath);
        
        // Add options based on config
        if (Config.includeHiddenFiles) {
            cmd.push("--hidden");
        }
        
        // Exclude extensions
        if (Config.excludedExtensions && Config.excludedExtensions.length > 0) {
            Config.excludedExtensions.forEach(ext => {
                cmd.push("--exclude");
                cmd.push(`*${ext}`);
            });
        }
        
        // Additional options
        cmd.push("--type", "f"); // files
        cmd.push("--type", "d"); // directories
        cmd.push("--max-results", root.maxResults.toString());
        cmd.push("--color", "never");
        cmd.push("--absolute-path");
        
        searchProcess.command = cmd;
        searchProcess.myOperationId = root.operationId;  // Tag this process with current operation
        searchProcess.running = true;
    }

    function openFile(filePath) {
        Quickshell.execDetached({
            command: ["xdg-open", filePath]
        });
    }

    function openContainingFolder(filePath) {
        const parentPath = filePath.substring(0, filePath.lastIndexOf('/'));
        Quickshell.execDetached({
            command: ["xdg-open", parentPath]
        });
    }

    function copyToClipboard(text) {
        // Use wl-copy for Wayland
        const copyProcess = Quickshell.exec({
            command: ["wl-copy", text]
        });
    }

    function listDirectory(dirPath) {
        // Increment operation ID to invalidate any previous operations
        root.operationId++;
        
        // Stop any running list process or search
        if (listProcess.running) {
            listProcess.running = false;
        }
        if (searchProcess.running) {
            searchProcess.running = false;
        }

        root.isSearching = true;
        root.hasPerformedSearch = false;  // Reset until results are ready

        // Expand ~ in directory path
        const expandedPath = root.expandTildePath(dirPath);

        // Build fd command to list directory contents (depth 1)
        let cmd = ["fd"];
        cmd.push(".");  // Match everything
        cmd.push(expandedPath);
        cmd.push("--max-depth", "1");
        cmd.push("--type", "f");  // files
        cmd.push("--type", "d");  // directories
        cmd.push("--color", "never");
        cmd.push("--absolute-path");
        
        if (Config.includeHiddenFiles) {
            cmd.push("--hidden");
        }

        listProcess.command = cmd;
        listProcess.myOperationId = root.operationId;  // Tag this process with current operation
        listProcess.running = true;
    }
}

