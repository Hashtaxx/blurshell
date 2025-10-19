import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.settings
import qs.services

// Delegate for each clipboard item
Rectangle {
    id: root
    // These properties are provided by the ListView delegate context
    required property var modelData
    required property int index

    // Properties passed from parent
    required property var logic
    required property int itemIndex

    readonly property bool itemSelected: (itemIndex === logic.currentItemIndex)
    property bool isHovered: false

    width: ListView.view.width
    // Dynamic height based on content type
    height: {
        if (modelData.isImage) {
            const imgH = Math.min(140, Math.max(64, (modelData.height || 120)));
            return imgH + 24; // padding
        }
        return 80; // text entries
    }
    // Color is determined by selection state and hover state
    color: {
        if (itemSelected) return Colors.brighten_10;
        if (isHovered) return Colors.darken_10;
        return Colors.darken_20;
    }
    radius: 12

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPositionChanged: logic.enableMouseSelection()
        onEntered: {
            root.isHovered = true;
            logic.selectItem(root.itemIndex);
        }
        onExited: {
            root.isHovered = false;
        }
        onClicked: {
            ClipService.copyAndPaste(root.modelData.entry);
            AppState.closeClipHist();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Image preview for image entries
        Item {
            id: imageContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.modelData.isImage

            readonly property int previewHeight: {
                const h = root.modelData.height || 0;
                return Math.min(140, Math.max(64, h || 120));
            }

            // Temp file path for decoded image
            property string tmpPath: "/tmp/qs-cliphist-" + (root.modelData.id || 0)

            // Helper to escape single quotes in shell
            function shellSingleQuoteEscape(s) {
                return String(s).replace(/'/g, "'\\''");
            }

            // Decode process; sets image source when finished
            Process {
                id: decodeProc
                command: ["bash", "-c", `echo '${imageContainer.shellSingleQuoteEscape(root.modelData.entry)}' | cliphist decode > '${imageContainer.tmpPath}'`]
                onRunningChanged: {
                    if (!running && previewImage.status !== Image.Loading) {
                        previewImage.source = imageContainer.tmpPath + "?t=" + Date.now();
                    }
                }
            }

            Component.onCompleted: {
                if (visible) {
                    decodeProc.running = true;
                }
            }

            Component.onDestruction: {
                // Clean up temp file
                Quickshell.execDetached(["bash", "-c", `[ -f '${tmpPath}' ] && rm -f '${tmpPath}'`]);
            }

            Image {
                id: previewImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                source: ""
            }
        }

        // Text content for non-image entries
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            visible: !root.modelData.isImage

            // Clipboard text preview
            Text {
                Layout.fillWidth: true
                text: root.modelData.text.length > 200 ? root.modelData.text.substring(0, 200) + "..." : root.modelData.text
                color: Colors.text
                font.pixelSize: Fonts.p
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            // Entry info display
            Text {
                text: `${root.modelData.timeAgo}`
                color: Qt.alpha(Colors.text, 0.5)
                font.pixelSize: 12
            }
        }
    }
}
