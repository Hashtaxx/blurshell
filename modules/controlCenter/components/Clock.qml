pragma ComponentBehavior: Bound

import QtQuick
import qs.settings
import qs.services

Column {
    id: timeColumn
    spacing: 4

    Text {
        text: Time.time
        color: Colors.text
        font.pixelSize: Fonts.h1
        font.weight: Font.Bold
    }

    Text {
        text: Time.fulldate
        color: Colors.text
        font.pixelSize: Fonts.p
        font.weight: Font.Light
    }
}
