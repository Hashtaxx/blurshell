pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.UPower
import qs.settings
import qs.services
import qs.components.animations

/**
 * PowerModeExpanded.qml
 * 
 * Displays system power management interface with battery status, performance profiles, and warnings.
 * Integrates with UPower service to provide power profile switching (Performance, Balanced, Power Saver).
 * Shows battery percentage, charging state, performance degradation warnings, and active profile holds.
 */
ExpandedBubble {
    id: root

    title: "Power Mode"
    showHeader: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            visible: Power.hasBattery
            color: Colors.brighten_3
            radius: 12

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Text {
                    text: Fonts.iconBattery
                    color: Colors.text
                    font.pixelSize: 24
                    font.family: Fonts.iconFont
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Battery"
                        color: Colors.text
                        font.pixelSize: Fonts.h5
                        font.weight: Font.Medium
                    }

                    Text {
                        text: {
                            const percentage = Power.batteryPercentage + "%"
                            if (Power.isCharging) return percentage + " (Charging)"
                            if (Power.isDischarging) return percentage + " (Discharging)"
                            if (Power.isFull) return percentage + " (Full)"
                            return percentage
                        }
                        color: Colors.textSubdued
                        font.pixelSize: Fonts.p
                    }
                }

                Text {
                    visible: Power.onBattery
                    text: Fonts.iconTrue
                    color: Colors.green
                    font.pixelSize: 20
                    font.family: Fonts.iconFont
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            visible: Power.degradationReason !== PerformanceDegradationReason.None
            color: Colors.yellow
            radius: 8
            
            property int contentHeight: degradationLayout.implicitHeight + 24

            RowLayout {
                id: degradationLayout
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Text {
                    text: Fonts.iconInfo
                    color: Colors.bg
                    font.pixelSize: 20
                    font.family: Fonts.iconFont
                }

                Text {
                    Layout.fillWidth: true
                    text: "Performance limited: " + Power.getDegradationReasonString()
                    color: Colors.bg
                    font.pixelSize: Fonts.p
                    wrapMode: Text.WordWrap
                }
            }
        }

        // Power Saver Profile
        PowerProfileItem {
            Layout.fillWidth: true
            Layout.fillHeight: true
            profileType: PowerProfile.PowerSaver
            isActive: Power.isProfileActive(PowerProfile.PowerSaver)
            isAvailable: true

            onClicked: Power.setPowerSaver()
        }

        // Balanced Profile
        PowerProfileItem {
            Layout.fillWidth: true
            Layout.fillHeight: true
            profileType: PowerProfile.Balanced
            isActive: Power.isProfileActive(PowerProfile.Balanced)
            isAvailable: true

            onClicked: Power.setBalanced()
        }

        // Performance Profile
        PowerProfileItem {
            Layout.fillWidth: true
            Layout.fillHeight: true
            profileType: PowerProfile.Performance
            isActive: Power.isProfileActive(PowerProfile.Performance)
            isAvailable: Power.hasPerformanceProfile

            onClicked: Power.setPerformance()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: holdsColumn.implicitHeight + 24
            visible: Power.holds && Power.holds.length > 0
            color: Colors.brighten_3
            radius: 8

            ColumnLayout {
                id: holdsColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "Active Profile Holds"
                    color: Colors.text
                    font.pixelSize: Fonts.h5
                    font.weight: Font.Medium
                }

                Repeater {
                    model: Power.holds

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: Fonts.iconInfo
                            color: Colors.textSubdued
                            font.pixelSize: 14
                            font.family: Fonts.iconFont
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.applicationId + ": " + modelData.reason
                            color: Colors.textSubdued
                            font.pixelSize: Fonts.p
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
