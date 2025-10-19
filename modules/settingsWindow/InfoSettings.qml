import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.modules.settingsWindow.components
import qs.settings

Item {
    id: root
    width: parent.width
    height: contentColumn.height + 40

    Column {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 20
        }
        spacing: 4

        Text {
            text: "Info"
            font.pixelSize: Fonts.h2
            color: Colors.text
        }

        LineSpacer {}

        // Version Section

        Rectangle {
            width: parent.width
            height: versionText.height + 30
            color: Colors.darken_20
            radius: 8

            Row {
                id: versionText
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 4

                Text {
                    text: "Version: BlurShell v0.1.0"
                    font.pixelSize: Fonts.h4
                    color: Colors.text
                }
            }
        }

        LineSpacer {}

        // Common Issues Link
        Rectangle {
            width: parent.width
            height: issuesContent.height + 24
            color: issuesHovered ? Colors.brighten_10 : Colors.darken_20
            radius: 8

            property bool issuesHovered: false

            Column {
                id: issuesContent
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 4

                IconAndText {
                    iconText: Fonts.iconGithub
                    labelText: "Common Issues"
                    fontSize: Fonts.h5
                }

                Text {
                    text: "Something's not working? Check out common issues in the README"
                    font.pixelSize: Fonts.p
                    color: Colors.brighten_50
                    wrapMode: Text.WordWrap
                    width: parent.width - 32
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally("https://github.com/Hashtaxx/BlurShell")
                onEntered: parent.issuesHovered = true
                onExited: parent.issuesHovered = false
            }
        }
    }
}
