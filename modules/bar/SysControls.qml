import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

RowLayout {
    id: root
    spacing: 8

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink].filter(n => n)
    }

    readonly property var sinkAudio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property int volNumber: sinkAudio ? Math.round(sinkAudio.volume * 100) : 0
    readonly property bool isMuted: sinkAudio ? sinkAudio.muted : false
    readonly property string volIcon: isMuted || volNumber === 0 ? "󰝟" : (volNumber < 50 ? "󰖀" : "󰕾")

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
            Text {
                text: root.volIcon
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 13
                color: root.isMuted ? "#f38ba8" : "#89b4fa"
            }
            Text {
                text: root.volNumber + "%"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                font.weight: Font.Bold
                color: "#cdd6f4"
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.sinkAudio) root.sinkAudio.muted = !root.sinkAudio.muted;
            }
            onWheel: wheel => {
                if (!root.sinkAudio) return;
                let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                root.sinkAudio.volume = Math.max(0.0, Math.min(1.0, root.sinkAudio.volume + delta));
            }
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
                    Quickshell.execDetached(["take-screenshot"]);
                } else {
                    Quickshell.execDetached(["take-screenshot", "region"]);
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

        property int batPercent: 100
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
