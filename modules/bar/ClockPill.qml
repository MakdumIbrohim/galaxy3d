import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    height: 34
    implicitWidth: centerRow.implicitWidth + 24
    radius: 17
    color: Qt.rgba(0.08, 0.08, 0.12, 0.85)
    border.color: Qt.rgba(1, 1, 1, 0.15)
    border.width: 1

    RowLayout {
        id: centerRow
        anchors.centerIn: parent
        spacing: 12

        Text {
            id: miniClock
            text: Qt.formatTime(new Date(), "HH:mm:ss")
            font.family: "JetBrains Mono"
            font.weight: Font.Bold
            font.pixelSize: 12
            color: "#ffffff"

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: miniClock.text = Qt.formatTime(new Date(), "HH:mm:ss")
            }
        }

        Rectangle { width: 1; height: 14; color: Qt.rgba(1, 1, 1, 0.2) }

        Text {
            id: miniDate
            text: Qt.formatDate(new Date(), "dddd, MMM dd")
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            color: "#a6adc8"
        }

        Rectangle { width: 1; height: 14; color: Qt.rgba(1, 1, 1, 0.2) }

        Text {
            text: " 31.5°C"
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            color: "#89b4fa"
        }
    }
}
