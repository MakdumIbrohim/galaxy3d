import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../components"

ColumnLayout {
    id: root
    required property var theme
    property var sinkAudio: null
    property var sourceAudio: null

    spacing: 16

    Text {
        text: "AUDIO STATIONS & VOLUME CONTROL"
        font.family: "JetBrains Mono"
        font.bold: true
        font.pixelSize: 11
        color: root.theme.subtext0
    }

    // Master Output Volume Card
    Rectangle {
        Layout.fillWidth: true
        height: 84
        radius: 12
        color: root.theme.surface0
        border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "󰕾"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18; color: root.theme.blue }
                Text { text: "Master Output Stream"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: root.theme.text; Layout.fillWidth: true }
                Rectangle {
                    width: 50; height: 22; radius: 6
                    color: root.theme.mantle
                    Text {
                        anchors.centerIn: parent
                        text: Math.round((root.sinkAudio ? root.sinkAudio.volume : 0.75) * 100) + "%"
                        font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; color: root.theme.blue
                    }
                }
            }

            SciFiSlider {
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                value: root.sinkAudio ? root.sinkAudio.volume : 0.75
                trackColor: root.theme.blue
                bgTrackColor: root.theme.surface1
                onMoved: function(val) {
                    if (root.sinkAudio) root.sinkAudio.volume = val;
                }
            }
        }
    }

    // Microphone Input Volume Card
    Rectangle {
        Layout.fillWidth: true
        height: 84
        radius: 12
        color: root.theme.surface0
        border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "󰍬"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18; color: root.theme.peach }
                Text { text: "Microphone Input Stream"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: root.theme.text; Layout.fillWidth: true }
                Rectangle {
                    width: 50; height: 22; radius: 6
                    color: root.theme.mantle
                    Text {
                        anchors.centerIn: parent
                        text: Math.round((root.sourceAudio ? root.sourceAudio.volume : 0.50) * 100) + "%"
                        font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; color: root.theme.peach
                    }
                }
            }

            SciFiSlider {
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                value: root.sourceAudio ? root.sourceAudio.volume : 0.50
                trackColor: root.theme.peach
                bgTrackColor: root.theme.surface1
                onMoved: function(val) {
                    if (root.sourceAudio) root.sourceAudio.volume = val;
                }
            }
        }
    }

    // Interface Sound Effects (SFX) Card
    Rectangle {
        Layout.fillWidth: true
        height: 64
        radius: 12
        color: root.theme.surface0
        border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text { text: "󰓃"; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: root.theme.accent }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Interface Audio Feedback (SFX)"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 11; color: root.theme.text }
                Text { text: "Futuristic audio feedback for buttons, radar sweep, and toggles"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.subtext0 }
            }

            SciFiSwitch {
                checked: ShellBridge.sfxEnabled
                activeColor: root.theme.accent
                inactiveColor: root.theme.surface1
                borderColor: root.theme.surface2
                subtextColor: root.theme.subtext0
                onToggled: function(newState) {
                    ShellBridge.setSfx(newState);
                    if (newState) AudioSfx.playClick();
                }
            }
        }
    }
}
