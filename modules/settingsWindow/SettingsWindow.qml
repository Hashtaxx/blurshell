import QtQuick
import QtQuick.Controls
import Quickshell
import QtQuick.Layouts
import qs.settings
import qs.components


FloatingWindow {
    id: root

    property var pages: [

        {
            "name": "General",
            "icon": Fonts.iconGeneralSettings,
            "component": "GeneralSettings.qml"
        },
        {
            "name": "Components",
            "icon": Fonts.iconSettings,
            "component": "ComponentsSettings.qml"
        },
        {
            "name": "Wallpaper",
            "icon": Fonts.iconImage,
            "component": "WallpaperSettings.qml"
        },
        {
            "name": "Info",
            "icon": Fonts.iconInfo,
            "component": "InfoSettings.qml"
        }
    ]
    property int currentPage: 0
    property int spacings: 12
    minimumSize: "800x500"
    maximumSize: "2000x1000"
    implicitWidth: 1100
    implicitHeight: 800

    visible: true
    title: "Quickshell Settings"
    color: Colors.bgBlur
    
    // Sync window visibility with AppState
    onVisibleChanged: {
        if (!visible && AppState.settingsWindowVisible) {
            AppState.closeSettingsWindow()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: root.spacings
        anchors.margins: root.spacings / 3

        Rectangle {
            id: sideBarWrapper
            color: "transparent"
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.minimumWidth: 200
            Layout.preferredWidth: 250
            Layout.maximumWidth: 400
            Layout.leftMargin: root.spacings
            Layout.topMargin: root.spacings
            Layout.bottomMargin: root.spacings

            Column {
                anchors.top: parent.top
                width: parent.width - 16
                anchors.margins: root.spacings
                spacing: root.spacings

                    /* Header / title area */
                    Rectangle {
                        width: parent.width
                        height: title.implicitHeight + root.spacings
                        color: "transparent"
                        radius: 8

                        Text {
                            id: title
                            text: "Settings"
                            font.pixelSize: Fonts.h1
                            color: Colors.text
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                        }
                    }

                    /* Menu items generated from root.pages */
                    Column {
                        id: menuColumn
                        width: parent.width
                        spacing: root.spacings / 2

                        Repeater {
                            model: root.pages
                            delegate: Rectangle {
                                id: menuItem
                                width: parent.width
                                height: 44
                                radius: 6
                                property bool hovered: false
                                color: root.currentPage === index ? Colors.brighten_10 : (hovered ? Colors.brighten_3 : "transparent")


                                IconAndText {
                                    iconText: modelData.icon
                                    labelText: modelData.name
                                    fontSize: Fonts.h5
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentPage = index
                                    onEntered: menuItem.hovered = true
                                    onExited: menuItem.hovered = false
                                }
                            }
                        }
                    }
            }
        }

        Rectangle {
            id: mainArea

            color: Colors.brighten_3
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 200
            Layout.preferredWidth: 800
            radius: Config.windowRounding

            ScrollView {
                anchors.fill: parent
                anchors.margins: root.spacings
                clip: true
                
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                Loader {
                    id: contentLoader
                    width: parent.width
                    source: root.pages[root.currentPage].component
                    onLoaded: {
                        if (item) {
                            item.anchors.fill = undefined
                        }
                    }
                }
            }

        }

    }

}
