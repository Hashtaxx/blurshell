// Searchbar.qml
// Text input field with integrated search functionality and keyboard navigation support
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.settings
import qs.modules.launcher

FocusScope {
    id: root

    property alias text: textField.text
    property alias placeholderText: textField.placeholderText
    property color textColor: Colors.text
    property color backgroundColor: Colors.brighten_10
    property int borderRadius: 32

    signal navigateDown
    signal navigateUp
    signal navigateRight
    signal executeSelected
    signal closeRequested
    signal tabPressed
    signal tabPressedReverse

    implicitHeight: LauncherConfig.searchBarHeight
    implicitWidth: 400
    focus: true

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: root.backgroundColor
        radius: root.borderRadius

        TextField {
            id: textField
            anchors.fill: parent
            anchors.margins: 8
            background: null
            selectByMouse: true
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            focus: true
            color: root.textColor
            font.pixelSize: Fonts.h4

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Tab:
                    root.tabPressed();
                    event.accepted = true;
                    break;
                case Qt.Key_Backtab:
                    root.tabPressedReverse();
                    event.accepted = true;
                    break;
                case Qt.Key_Down:
                    root.navigateDown();
                    event.accepted = true;
                    break;
                case Qt.Key_Up:
                    root.navigateUp();
                    event.accepted = true;
                    break;
                case Qt.Key_Right:
                    root.navigateRight();
                    event.accepted = true;
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.executeSelected();
                    event.accepted = true;
                    break;
                default:
                    break;
                }
            }
        }
    }
}
