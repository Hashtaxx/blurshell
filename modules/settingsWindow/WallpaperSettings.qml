import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.settings
import qs.modules.settingsWindow.components

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
            text: "Wallpaper Settings"
            font.pixelSize: Fonts.h2
            color: Colors.text
        }

        LineSpacer {}

        // Source Settings Section
        Text {
            text: "Source"
            font.pixelSize: Fonts.h3
            color: Colors.text
        }

        LineSetting {
            labelText: "Cycle through a directory"
            iconText: Fonts.iconFolder
            width: parent.width

            Toggle {
                checked: Config.useWallpaperDirectory

                onToggled: checked => {
                    Config.set.useWallpaperDirectory = checked;
                    console.log("Use wallpaper directory:", checked);
                }
            }
        }

        LineSetting {
            labelText: "Wallpaper Directory"
            iconText: Fonts.iconFolderOpen
            width: parent.width

            TextInput {
                fieldWidth: 300
                text: Config.wallpaperDirectory
                placeholderText: "~/Pictures/Wallpapers"
                onTextEdited: text => {
                    Config.set.wallpaperDirectory = Config.collapsePath(text);
                }
            }
        }

        // Image Picker - fills remaining space
        ImagePicker {
            id: imagePicker
            directoryPath: Config.wallpaperDirectory
            selectedImagePath: Config.wallpaperPath
            thumbnailSize: 140
            spacing: 16

            visible: !Config.useWallpaperDirectory
            Layout.fillWidth: true
            Layout.preferredHeight: 500

            onImageSelected: imagePath => {
                                 Config.set.wallpaperPath = Config.collapsePath(imagePath);
                             }
        }


        LineSpacer {
            visible: Config.useWallpaperDirectory
        }

        // Auto-Rotation Settings Section
        Text {
            text: "Auto-Rotation"
            font.pixelSize: Fonts.h3
            color: Colors.text
            visible: Config.useWallpaperDirectory
        }

        LineSetting {
            labelText: "Auto-Rotate Enabled"
            iconText: Fonts.iconReboot
            width: parent.width
            visible: Config.useWallpaperDirectory

            Toggle {
                checked: Config.autoRotateEnabled

                onToggled: checked => {
                    Config.set.autoRotateEnabled = checked;
                    console.log("Auto-rotate enabled:", checked);
                }
            }
        }

        LineSetting {
            labelText: "Rotation Interval (minutes)"
            iconText: Fonts.iconTimer
            width: parent.width
            visible: Config.useWallpaperDirectory
            opacity: Config.autoRotateEnabled ? 1.0 : 0.5

            RangeSlider {
                enabled: Config.autoRotateEnabled
                from: 1
                to: 120
                value: Config.autoRotateInterval / 60000
                stepSize: 1
                sliderWidth: 200

                onSliderValueChanged: value => {
                    Config.set.autoRotateInterval = value * 60000;
                    console.log("Auto-rotate interval:", value, "minutes");
                }
            }
        }

        LineSetting {
            labelText: "Pause on Manual Change"
            iconText: Fonts.iconPause
            width: parent.width
            visible: Config.useWallpaperDirectory
            opacity: Config.autoRotateEnabled ? 1.0 : 0.5

            Toggle {
                enabled: Config.autoRotateEnabled
                checked: Config.pauseAutoRotateOnManual

                onToggled: checked => {
                    Config.set.pauseAutoRotateOnManual = checked;
                    console.log("Pause on manual change:", checked);
                }
            }
        } 
        
        LineSpacer {}

        // Effects Settings Section
        Text {
            text: "Effects"
            font.pixelSize: Fonts.h3
            color: Colors.text
        }

        LineSetting {
            labelText: "Show Splash on Wallpaper"
            iconText: Fonts.iconSplash
            width: parent.width

            Toggle {
                checked: Config.showSplashOnWallpaper

                onToggled: checked => {
                    Config.set.showSplashOnWallpaper = checked;
                    console.log("Show splash on wallpaper:", checked);
                }
            }
        }
    }
}
