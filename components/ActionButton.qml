// ActionButton.qml
// Circular action button with icon, loading spinner, and click handling
// Supports disabled state, hover effects, and smooth animations
pragma ComponentBehavior: Bound
import QtQuick
import qs.settings
import qs.components.animations

Rectangle {
    id: root

    // Public properties
    property string icon: ""
    property real iconSize: 0.5
    property color backgroundColor: "transparent"
    property color borderColor: Colors.text
    property color textColor: Colors.text
    property bool loading: false
    property bool enabled: true
    
    // Signal for proper QML signal/slot connections
    signal clicked()
    
    // Expose mouse state
    readonly property alias containsMouse: mouseArea.containsMouse

    // Appearance
    width: parent.height
    height: width
    radius: width
    color: backgroundColor
    border.width: 1
    border.color: borderColor
    scale: mouseArea.containsMouse && enabled && !loading ? 1 : 0.95
    opacity: enabled && !loading ? 1.0 : 0.5

    AnimatedScale on scale {}
    AnimatedColor on color {}
    AnimatedOpacity on opacity {}

    // Icon
    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.textColor
        font.pixelSize: parent.width * root.iconSize
        font.family: Fonts.iconFont
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        visible: !root.loading
        opacity: root.loading ? 0.0 : 1.0

        AnimatedColor on color {}
        AnimatedOpacity on opacity {}
    }

    // Mouse interaction
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled && !root.loading ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: root.enabled && !root.loading
        onClicked: root.clicked()
    }
    
    // Modern loading spinner
    Item {
        anchors.centerIn: parent
        width: parent.width * 0.55
        height: width
        visible: root.loading
        opacity: root.loading ? 1.0 : 0.0
        
        AnimatedOpacity on opacity {}
        
        // Circular progress arc
        Canvas {
            id: spinnerCanvas
            anchors.fill: parent
            property real rotation
            
            onRotationChanged: requestPaint()
            
            onPaint: {
                var ctx = getContext("2d");
                var centerX = width / 2;
                var centerY = height / 2;
                var radius = width / 2 - 2;
                
                ctx.clearRect(0, 0, width, height);
                
                // Draw arc
                ctx.lineWidth = 2.5;
                ctx.lineCap = "round";
                ctx.strokeStyle = root.textColor;
                
                var startAngle = rotation * Math.PI / 180;
                var endAngle = startAngle + 270 * Math.PI / 180;
                
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);
                ctx.stroke();
            }
            
            NumberAnimation on rotation {
                from: 0
                to: 360
                duration: 1200
                loops: Animation.Infinite
                running: root.loading
                easing.type: Easing.Linear
            }
        }
    }
}