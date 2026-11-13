import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../../theme"

PanelWindow {
    id: osdWindow

    WlrLayershell.namespace: "galaxy3d-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors {
        bottom: true
    }
    margins.bottom: 72

    implicitWidth: 260
    implicitHeight: 52

    MatugenColors { id: theme }

    property string mode: "volume"
    property real level: 0.0
    property string icon: "󰕾"
    property color iconColor: theme.blue
    property bool isVisible: false
    property bool isInitialized: false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink].filter(n => n)
    }

    readonly property var sinkAudio: Pipewire.defaultAudioSink?.audio ?? null

    Connections {
        target: osdWindow.sinkAudio
        function onVolumeChanged() {
            if (!osdWindow.isInitialized) return;
            osdWindow.mode = "volume";
            osdWindow.level = osdWindow.sinkAudio ? osdWindow.sinkAudio.volume : 0.0;
            osdWindow.iconColor = (osdWindow.sinkAudio && osdWindow.sinkAudio.muted) ? theme.red : theme.blue;
            osdWindow.icon = (osdWindow.sinkAudio && osdWindow.sinkAudio.muted) || osdWindow.level === 0
                ? "󰝟"
                : (osdWindow.level < 0.5 ? "󰖀" : "󰕾");
            osdWindow.show();
        }
        function onMutedChanged() {
            if (!osdWindow.isInitialized) return;
            onVolumeChanged();
        }
    }

    Process {
        id: brightnessReader
        command: ["bash", "-c", "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo '50'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(this.text.trim());
                if (!isNaN(val)) {
                    osdWindow.mode = "brightness";
                    osdWindow.level = val / 100.0;
                    osdWindow.icon = "󰃟";
                    osdWindow.iconColor = theme.peach;
                    if (osdWindow.isInitialized) osdWindow.show();
                }
            }
        }
    }

    Process {
        id: brightnessWatcher
        running: true
        command: ["bash", "-c", "while inotifywait -qq -e modify /sys/class/backlight/*/actual_brightness 2>/dev/null; do echo 'changed'; sleep 0.05; done"]
        stdout: SplitParser {
            onRead: data => {
                brightnessReader.running = false;
                brightnessReader.running = true;
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1600
        onTriggered: osdWindow.isVisible = false
    }

    function show() {
        isVisible = true;
        hideTimer.restart();
    }

    Component.onCompleted: {
        brightnessReader.running = true;
        initTimer.start();
    }

    Timer {
        id: initTimer
        interval: 1500
        onTriggered: osdWindow.isInitialized = true
    }

    Item {
        anchors.fill: parent
        opacity: osdWindow.isVisible ? 1.0 : 0.0
        scale: osdWindow.isVisible ? 1.0 : 0.88

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

        Rectangle {
            anchors.fill: parent
            radius: 26
            color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.94)
            border.color: Qt.rgba(osdWindow.iconColor.r, osdWindow.iconColor.g, osdWindow.iconColor.b, 0.45)
            border.width: 1.5

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Text {
                    text: osdWindow.icon
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 20
                    color: osdWindow.iconColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.8)

                    Rectangle {
                        height: parent.height
                        width: Math.max(8, parent.width * Math.max(0.0, Math.min(1.0, osdWindow.level)))
                        radius: 4
                        color: osdWindow.iconColor
                        Behavior on width { NumberAnimation { duration: 100 } }
                    }
                }

                Text {
                    text: Math.round(osdWindow.level * 100) + "%"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: theme.text
                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
