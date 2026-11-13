import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    id: root
    spacing: 8

    Rectangle {
        height: 34
        implicitWidth: 70
        radius: 17
        color: Qt.rgba(0.08, 0.08, 0.12, 0.85)
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: 6
            Text { text: "󰕾"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: "#89b4fa" }
            Text { text: "76%"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.Bold; color: "#cdd6f4" }
        }
    }

    Rectangle {
        height: 34
        width: 34
        radius: 17
        color: Qt.rgba(0.08, 0.08, 0.12, 0.85)
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 13
            color: "#89b4fa"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    Quickshell.execDetached(["/home/makdumibrohim/.local/bin/take-screenshot"]);
                } else {
                    Quickshell.execDetached(["/home/makdumibrohim/.local/bin/take-screenshot", "region"]);
                }
            }
        }
    }

    Rectangle {
        id: batteryBox
        height: 34
        implicitWidth: 72
        radius: 17
        color: Qt.rgba(0.08, 0.08, 0.12, 0.85)
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1

        property int batPercent: 78
        property bool isCharging: false

        Process {
            id: batReader
            running: true
            command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1"]
            stdout: SplitParser {
                onRead: data => {
                    let val = data.trim();
                    if (!isNaN(parseInt(val))) {
                        batteryBox.batPercent = parseInt(val);
                    } else if (val.toLowerCase() === "charging") {
                        batteryBox.isCharging = true;
                    } else if (val.toLowerCase() === "discharging") {
                        batteryBox.isCharging = false;
                    }
                }
            }
        }

        Timer {
            interval: 10000
            running: true
            repeat: true
            onTriggered: { batReader.running = false; batReader.running = true; }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: batteryBox.isCharging ? "󰂄" : "󰁹"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 14
                color: batteryBox.batPercent > 20 ? "#a6e3a1" : "#f38ba8"
            }
            Text {
                text: Math.round(batteryBox.batPercent) + "%"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                font.weight: Font.Bold
                color: "#cdd6f4"
            }
        }
    }
}
