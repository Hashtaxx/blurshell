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

    // Build model from available screens
    property var monitorModel: {
        var model = [];
        for (let i = 0; i < Quickshell.screens.length; i++) {
            const screen = Quickshell.screens[i];
            model.push({
                itemText: screen.name,
                itemIcon: Fonts.iconMonitor,
                itemIconColor: Colors.text,
                isSeparator: false,
                itemAction: screen.name
            });
        }
        return model;
    }

    property var themeModel: [
        {
            itemText: "Catppuccin Mocha",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.text,
            isSeparator: false,
            itemAction: "CatppuccinMocha"
        },
        {
            itemText: "Catppuccin Latte",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.text,
            isSeparator: false,
            itemAction: "CatppuccinLatte"
        },
        {
            itemText: "Catppuccin Frappe",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.text,
            isSeparator: false,
            itemAction: "CatppuccinFrappe"
        },
        {
            itemText: "Catppuccin Macchiato",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.text,
            isSeparator: false,
            itemAction: "CatppuccinMacchiato"
        }
    ]

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
            text: "General Settings"
            font.pixelSize: Fonts.h2
            color: Colors.text
        }

        LineSpacer {}

        // Display Settings Section
        Text {
            text: "Display"
            font.pixelSize: Fonts.h3
            color: Colors.text
        }

        LineSetting {
            labelText: "Main Monitor"
            iconText: Fonts.iconMonitor
            width: parent.width

            Dropdown {
                buttonText: Config.mainMonitorId
                buttonWidth: 200
                model: root.monitorModel

                onItemClicked: (action, data) => {
                    Config.set.mainMonitorId = action;
                    console.log("Main monitor changed to:", data.text);
                }
            }
        }

        LineSpacer {}

        // Lock Screen Settings Section
        Text {
            text: "Lock Screen"
            font.pixelSize: Fonts.h3
            color: Colors.text
        }

        LineSetting {
            labelText: "Lock on Startup"
            iconText: Fonts.iconLockSettings
            width: parent.width

            Toggle {
                checked: Config.lockOnStartup

                onToggled: checked => {
                    Config.set.lockOnStartup = checked;
                    console.log("Lock on startup:", checked);
                }
            }
        }

        LineSetting {
            labelText: "Lockscreen Dimming"
            iconText: Fonts.iconDimming
            width: parent.width

            RangeSlider {
                from: 0
                to: 1
                stepSize: 0.05
                value: Config.lockscreenDimming
                sliderWidth: 200

                onSliderValueChanged: value => {
                    Config.set.lockscreenDimming = value;
                    console.log("Lockscreen dimming:", value);
                }
            }
        }

        LineSetting {
            labelText: "Show Splash on Lockscreen"
            iconText: Fonts.iconSplash
            width: parent.width

            Toggle {
                checked: Config.showSplashOnLockscreen

                onToggled: checked => {
                    Config.set.showSplashOnLockscreen = checked;
                    console.log("Show splash on lockscreen:", checked);
                }
            }
        }

        LineSpacer {}

        // Appearance Settings Section
        Text {
            text: "Appearance"
            font.pixelSize: Fonts.h3
            color: Colors.text
        }

        LineSetting {
            labelText: "Theme"
            iconText: Fonts.iconTheme
            width: parent.width

            Dropdown {
                buttonText: Config.theme
                buttonWidth: 200
                model: root.themeModel

                onItemClicked: (action, data) => {
                    Config.set.theme = action;
                    console.log("Theme changed to:", data.text);
                }
            }
        }

        LineSetting {
            labelText: "Transparency"
            iconText: Fonts.iconEye
            width: parent.width

            RangeSlider {
                from: 0
                to: 1
                stepSize: 0.01
                value: Config.transparency
                sliderWidth: 200

                onSliderValueChanged: value => {
                    Config.set.transparency = value;
                    console.log("Transparency:", value);
                }
            }
        }

        LineSetting {
            labelText: "Window Rounding"
            iconText: Fonts.iconRoundedCorner
            width: parent.width

            RangeSlider {
                from: 0
                to: 30
                stepSize: 1
                value: Config.windowRounding
                sliderWidth: 200

                onSliderValueChanged: value => {
                    Config.set.windowRounding = Math.round(value);
                    console.log("Window rounding:", value);
                }
            }
        }

        LineSetting {
            labelText: "Gaps Out"
            iconText: Fonts.iconGapsOut
            width: parent.width

            RangeSlider {
                from: 0
                to: 50
                stepSize: 1
                value: Config.gapsOut
                sliderWidth: 200

                onSliderValueChanged: value => {
                    Config.set.gapsOut = Math.round(value);
                    console.log("Gaps out:", value);
                }
            }
        }

        LineSetting {
            labelText: "Gaps In"
            iconText: Fonts.iconGapsIn
            width: parent.width

            RangeSlider {
                from: 0
                to: 30
                stepSize: 1
                value: Config.gapsIn
                sliderWidth: 200

                onSliderValueChanged: value => {
                    Config.set.gapsIn = Math.round(value);
                    console.log("Gaps in:", value);
                }
            }
        }

        LineSetting {
            labelText: "Drawer Margins"
            iconText: Fonts.iconGapsOut
            width: parent.width

            RangeSlider {
                from: 0
                to: 40
                stepSize: 2
                value: Config.drawerMargins
                sliderWidth: 200

                onSliderValueChanged: value => {
                    Config.set.drawerMargins = Math.round(value);
                    console.log("Drawer Margins:", value);
                }
            }
        }
    }
}
