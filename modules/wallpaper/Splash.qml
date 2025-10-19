import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.settings
import qs.services

Scope {
    id: splashScope

    // Create one splash window per screen
    Mainscreen {
        id: screenVariants

        delegate: PanelWindow {
            id: splashWindow
            
            required property var modelData
            
            screen: modelData
            exclusionMode : ExclusionMode.Ignore

            anchors {
                right: true
                bottom: true
            }

            margins{
                bottom: 50
                right: 100
            }

            implicitWidth: content.width
            implicitHeight: content.height

            color: "transparent"

            // Give the window an empty click mask so all clicks pass through it
            mask: Region {}

            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.layer: WlrLayer.Bottom


            ColumnLayout {
                id: content
                spacing: 2


                Text {
                    text: HyprStats.splash
                    color: Colors.text
                    font.pointSize: 14
                    horizontalAlignment: Text.AlignRight
                    Layout.alignment: Qt.AlignRight
                    Layout.preferredWidth : 400
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
