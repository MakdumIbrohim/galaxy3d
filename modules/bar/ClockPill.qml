import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../services"

Rectangle {
    id: root
    height: 34
    implicitWidth: centerRow.implicitWidth + 24
    radius: 17
    color: Qt.rgba(0.08, 0.08, 0.12, 0.85)
    border.color: Qt.rgba(1, 1, 1, 0.15)
    border.width: 1

    Caching { id: paths }

    property string weatherDisplay: "31°"
    property string weatherIcon: "󰖐"

    Process {
        id: weatherBarPoller
        running: true
        command: [paths.qsDir + "/services/galaxy3d-helper", "weather", "--current"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 2) {
                    root.weatherIcon = lines[0];
                    root.weatherDisplay = lines[1];
                }
            }
        }
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: { weatherBarPoller.running = false; weatherBarPoller.running = true; }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            miniClock.text = Qt.formatTime(d, "HH:mm:ss");
            miniDate.text = Qt.formatDate(d, "dddd, MMM dd");
        }
    }

    RowLayout {
        id: centerRow
        anchors.centerIn: parent
        spacing: 12

        Text {
            id: miniClock
            font.family: "JetBrains Mono"
            font.weight: Font.Bold
            font.pixelSize: 12
            color: "#ffffff"
        }

        Rectangle { width: 1; height: 14; color: Qt.rgba(1, 1, 1, 0.2) }

        Text {
            id: miniDate
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            color: "#a6adc8"
        }

        Rectangle { width: 1; height: 14; color: Qt.rgba(1, 1, 1, 0.2) }

        Text {
            text: root.weatherIcon + " " + root.weatherDisplay
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            color: "#89b4fa"
        }
    }
}
