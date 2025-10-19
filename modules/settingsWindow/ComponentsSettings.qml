import QtQuick
import QtQuick.Controls
import qs.components
import qs.modules.settingsWindow.components
import qs.settings

Item {
    id: root
    width: parent.width
    height: contentColumn.height + 40

    property var colorModel: [
        {
            itemText: "rosewater",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.rosewater,
            isSeparator: false,
            itemAction: "rosewater"
        },
        {
            itemText: "flamingo",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.flamingo,
            isSeparator: false,
            itemAction: "flamingo"
        },
        {
            itemText: "pink",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.pink,
            isSeparator: false,
            itemAction: "pink"
        },
        {
            itemText: "mauve",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.mauve,
            isSeparator: false,
            itemAction: "mauve"
        },
        {
            itemText: "red",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.red,
            isSeparator: false,
            itemAction: "red"
        },
        {
            itemText: "maroon",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.maroon,
            isSeparator: false,
            itemAction: "maroon"
        },
        {
            itemText: "peach",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.peach,
            isSeparator: false,
            itemAction: "peach"
        },
        {
            itemText: "yellow",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.yellow,
            isSeparator: false,
            itemAction: "yellow"
        },
        {
            itemText: "green",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.green,
            isSeparator: false,
            itemAction: "green"
        },
        {
            itemText: "teal",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.teal,
            isSeparator: false,
            itemAction: "teal"
        },
        {
            itemText: "sky",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.sky,
            isSeparator: false,
            itemAction: "sky"
        },
        {
            itemText: "sapphire",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.sapphire,
            isSeparator: false,
            itemAction: "sapphire"
        },
        {
            itemText: "blue",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.blue,
            isSeparator: false,
            itemAction: "blue"
        },
        {
            itemText: "lavender",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.lavender,
            isSeparator: false,
            itemAction: "lavender"
        },
        {
            itemText: "base",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.bg,
            isSeparator: false,
            itemAction: "base"
        },
        {
            itemText: "crust",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.textSecondary,
            isSeparator: false,
            itemAction: "crust"
        },
        {
            itemText: "mantle",
            itemIcon: Fonts.iconCircleFilled,
            itemIconColor: Colors.bgDark,
            isSeparator: false,
            itemAction: "mantle"
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
            text: "Component Settings"
            font.pixelSize: Fonts.h2
            color: Colors.text
        }

        LineSpacer {}

        // Launcher Settings Section
        Text {
            text: "Launcher"
            font.pixelSize: Fonts.h3
            color: Colors.text
        }

        LineSetting {
            labelText: "Accent Color"
            iconText: Fonts.iconPalette
            iconColor: Config.launcherAccent
            width: parent.width

            Dropdown {
                buttonText: Config.set.launcherAccent
                buttonWidth: 150
                model: root.colorModel

                onItemClicked: (action, data) => {
                    Config.set.launcherAccent = action;
                    console.log("Launcher accent changed to:", action);
                }
            }
        } 
        
        LineSetting {
            labelText: "Background Color"
            iconText: Fonts.iconPalette
            iconColor: Config.launcherBackground
            width: parent.width

            Dropdown {
                buttonText: Config.set.launcherBackground
                buttonWidth: 150
                model: root.colorModel

                onItemClicked: (action, data) => {
                                   Config.set.launcherBackground = action;
                                   console.log("Launcher background changed to:", action);
                               }
            }
        }

        LineSetting {
            labelText: "Launcher Width"
            iconText: Fonts.iconSpacing
            width: parent.width
            subTitle: "0 Defaults to 25% of Screen-width"
            minHeight: 60

            RangeSlider {
                from: 0
                to: 1000
                value: Config.launcherWidth
                stepSize: 10
                sliderWidth: 200

                onSliderValueChanged: value => {
                    Config.set.launcherWidth = value;
                    console.log("Launcher width set to:", value);
                }
            }
        }


        LineSpacer {
            height: 4
        }

        Column {
            id: excludedExtensions
            spacing: 8
            width: parent.width

            Text {
                text: "Excluded File-Extensions for search"
                font.pixelSize: Fonts.h5
                color: Colors.text
            }

            TagList {
                width: parent.width
                items: Config.excludedExtensions
                placeholderText: ".ext"

                onItemAdded: item => {
                    let newArray = [...Config.excludedExtensions, item];
                    Config.set.excludedExtensions = newArray;
                    console.log("Added extension:", item);
                }

                onItemRemoved: item => {
                    let newArray = [...Config.excludedExtensions];
                    let index = newArray.indexOf(item);
                    if (index > -1) {
                        newArray.splice(index, 1);
                        Config.set.excludedExtensions = newArray;
                        console.log("Removed extension:", item);
                    }
                }
            }
        }

        LineSpacer {}

        // Control Center Settings Section
        Text {
            text: "Control Center"
            font.pixelSize: Fonts.h3
            color: Colors.text
        }

        LineSetting {
            labelText: "Accent Color"
            iconText: Fonts.iconPalette
            iconColor: Config.controlCenterAccent
            width: parent.width

            Dropdown {
                buttonText: Config.set.controlCenterAccent
                buttonWidth: 150
                model: root.colorModel

                onItemClicked: (action, data) => {
                    Config.set.controlCenterAccent = action;
                    console.log("Control Center accent changed to:", action);
                }
            }
        }

        LineSetting {
            labelText: "Background Color"
            iconText: Fonts.iconPalette
            iconColor: Config.controlCenterBackground
            width: parent.width

            Dropdown {
                buttonText: Config.set.controlCenterBackground
                buttonWidth: 150
                model: root.colorModel

                onItemClicked: (action, data) => {
                    Config.set.controlCenterBackground = action;
                    console.log("Control Center background changed to:", action);
                }
            }
        }

        LineSetting {
            labelText: "Control Center Width"
            iconText: Fonts.iconSpacing
            width: parent.width
            subTitle: "0 Defaults to 20% of Screen-width"
            minHeight: 60

            RangeSlider {
                from: 0
                to: 1000
                value: Config.controlCenterWidth
                stepSize: 10
                sliderWidth: 200

                onSliderValueChanged: value => {
                    Config.set.controlCenterWidth = value;
                    console.log("Control Center width set to:", value);
                }
            }
        }

        LineSpacer {}

        // Bar Settings Section
        Text {
            text: "Bar"
            font.pixelSize: Fonts.h3
            color: Colors.text
        }

        LineSetting {
            labelText: "Show Volume Bar Always"
            iconText: Fonts.iconVolumeHigh
            width: parent.width

            Toggle {
                checked: Config.showVolumeBarAlways

                onToggled: checked => {
                    Config.set.showVolumeBarAlways = checked;
                    console.log("Show volume bar always:", checked);
                }
            }
        }

        LineSpacer {}

        // Clipboard History Settings Section
        Text {
            text: "Clipboard History"
            font.pixelSize: Fonts.h3
            color: Colors.text
        }

        LineSetting {
            labelText: "Accent Color"
            iconText: Fonts.iconPalette
            iconColor: Config.clipHistAccent
            width: parent.width

            Dropdown {
                buttonText: Config.set.clipHistAccent
                buttonWidth: 150
                model: root.colorModel

                onItemClicked: (action, data) => {
                    Config.set.clipHistAccent = action;
                    console.log("Clipboard History accent changed to:", action);
                }
            }
        }

        LineSetting {
            labelText: "Background Color"
            iconText: Fonts.iconPalette
            iconColor: Config.clipHistBackground
            width: parent.width

            Dropdown {
                buttonText: Config.set.clipHistBackground
                buttonWidth: 150
                model: root.colorModel

                onItemClicked: (action, data) => {
                    Config.set.clipHistBackground = action;
                    console.log("Clipboard History background changed to:", action);
                }
            }
        }

        LineSpacer {}

        Text {
            text: "Notifications"
            font.pixelSize: Fonts.h3
            color: Colors.text
        }

        LineSetting {
            labelText: "Notification Timeout (seconds)"
            iconText: Fonts.iconTimer
            width: parent.width

            RangeSlider {
                from: 1
                to: 30
                value: Config.defaultExpireTimeout / 1000
                stepSize: 1
                sliderWidth: 200

                onSliderValueChanged: value => {
                    Config.set.defaultExpireTimeout = value * 1000;
                    console.log("Notification timeout:", value, "seconds");
                }
            }
        }
    }
}
