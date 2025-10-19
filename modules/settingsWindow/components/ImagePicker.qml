pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.settings
import qs.components.animations

Item {
    id: root

    property string directoryPath: ""
    property int thumbnailSize: 120
    property int spacing: 12
    property string selectedImagePath: ""

    signal imageSelected(string imagePath)

    implicitWidth: parent.width
    implicitHeight: gridView.implicitHeight

    // Supported image extensions
    property var imageExtensions: [".jpg", ".jpeg", ".png", ".bmp", ".gif", ".svg"]

    // Process to list directory contents.
    // NOTE: This uses the system 'ls' command which is simple but not portable
    // or safe for arbitrary filenames (spaces/newlines). A future improvement
    // would be to replace this with a QDir listing from C++ or a JS-based
    // file API when possible.
    Process {
        id: listProcess
        // Use 'ls -1 <dir>' to print one filename per line.
        command: ["ls", "-1", root.directoryPath]
        running: root.directoryPath !== ""

        // Use SplitParser on stdout to receive one line per onRead call.
        stdout: SplitParser {
            splitMarker: "\n"

            onRead: data => {
                // SplitParser gives us one line at a time. Skip empty lines.
                if (data === "") {
                    return;
                }

                // Normalize to lowercase for extension checks.
                let lower = data.toLowerCase();

                // If the filename ends with a supported extension, append to model.
                for (let ext of root.imageExtensions) {
                    if (lower.endsWith(ext)) {
                        // Build the full file:// path for the Image source.
                        let fullPath = root.directoryPath + "/" + data;
                        imageModel.append({ imagePath: fullPath });
                        break;
                    }
                }
            }
        }

        // When the process starts we should clear the previous listing so the
        // GridView always reflects the latest directory contents.
        onRunningChanged: {
            if (running) {
                imageModel.clear();
            }
        }
    }

    ListModel {
        id: imageModel
    }

    // Background rectangle
    Rectangle {
        anchors.fill: parent
        color: Colors.darken_20
        radius: 8
    }

    GridView {
        id: gridView
        width: parent.width
        implicitHeight: contentHeight
        cellWidth: root.thumbnailSize + root.spacing
        cellHeight: root.thumbnailSize + root.spacing + 40 // Extra space for filename

        model: imageModel
        interactive: false

        delegate: Item {
            id: thumbnailDelegate
            required property string imagePath
            required property int index

            width: gridView.cellWidth
            height: gridView.cellHeight

            Rectangle {
                id: thumbnailContainer
                anchors.centerIn: parent
                width: root.thumbnailSize
                height: root.thumbnailSize + 30
                radius: 8
                color: mouseArea.containsMouse ? Colors.brighten_10 : "transparent"
                border.color: root.selectedImagePath === thumbnailDelegate.imagePath ? Colors.lavender : "transparent"
                border.width: 3

                AnimatedColor on color {}
                AnimatedColor on border.color {}

                Column {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    Rectangle {
                        width: parent.width
                        height: root.thumbnailSize - 16
                        radius: 6
                        color: Colors.brighten_10
                        clip: true

                        Image {
                            id: thumbnail
                            anchors.fill: parent
                            source: "file://" + thumbnailDelegate.imagePath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.color: Colors.brighten_10
                                border.width: 1
                                radius: 6
                            }

                            // Loading indicator
                            Text {
                                anchors.centerIn: parent
                                text: thumbnail.status === Image.Loading ? "Loading..." : thumbnail.status === Image.Error ? "Error" : ""
                                color: Colors.textSubdued
                                font.pixelSize: Fonts.p
                                visible: thumbnail.status !== Image.Ready
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: {
                            let parts = thumbnailDelegate.imagePath.split('/');
                            return parts[parts.length - 1];
                        }
                        color: mouseArea.containsMouse ? Colors.text : Colors.textSubdued
                        font.pixelSize: Fonts.p
                        elide: Text.ElideMiddle
                        horizontalAlignment: Text.AlignHCenter

                        AnimatedColor on color {}
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.selectedImagePath = thumbnailDelegate.imagePath;
                        root.imageSelected(thumbnailDelegate.imagePath);
                    }
                }
            }
        }
    }
}
