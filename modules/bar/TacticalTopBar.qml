import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../../theme"
import "../../services"

Item {
    id: root
    anchors.fill: parent

    MatugenColors { id: theme }
    Caching { id: paths }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink].filter(n => n)
    }

    readonly property var sinkAudio: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio : null
    readonly property int volNumber: sinkAudio ? Math.round(sinkAudio.volume * 100) : 0
    readonly property bool isMuted: sinkAudio ? sinkAudio.muted : false

    readonly property MprisPlayer activePlayer: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    property string timeStr: "00:00:00"
    property string dateStr: "MON 16"
    property string weatherDisplay: "30°"

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            root.timeStr = Qt.formatTime(d, "HH:mm:ss");
            root.dateStr = Qt.formatDate(d, "ddd dd").toUpperCase();
        }
    }

    Process {
        id: weatherPoller
        running: true
        command: [paths.qsDir + "/services/galaxy3d-helper", "weather", "--current"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 2) {
                    root.weatherDisplay = lines[1];
                }
            }
        }
    }

    // Full-Width Background HUD Rail
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.88)

        // Bottom Luminous Rail
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1.5
            color: Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.45)
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18

        // Left Section: Brackets & Workspaces
        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Text {
                text: "[ GALAXY // 3D ]"
                font.family: "JetBrains Mono"
                font.weight: Font.Black
                font.pixelSize: 11
                color: theme.teal

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellBridge.toggleLauncher()
                }
            }

            Row {
                spacing: 4
                Repeater {
                    model: 5
                    delegate: Text {
                        readonly property int wsId: index + 1
                        readonly property bool isCurrent: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                        text: "[" + wsId + "]"
                        font.family: "JetBrains Mono"
                        font.weight: isCurrent ? Font.Bold : Font.Normal
                        font.pixelSize: 11
                        color: isCurrent ? theme.yellow : Qt.rgba(theme.subtext0.r, theme.subtext0.g, theme.subtext0.b, 0.5)

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", wsId.toString()])
                        }
                    }
                }
            }

            // Tactical Media Readout
            Text {
                visible: root.activePlayer !== null
                text: {
                    if (!root.activePlayer) return "";
                    let t = root.activePlayer.trackTitle || "AUDIO";
                    return "// " + t.toUpperCase();
                }
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                color: theme.mauve
                elide: Text.ElideRight
                Layout.maximumWidth: 180

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellBridge.toggleMedia()
                }
            }
        }

        // Center Section: Tactical Timecode
        Item {
            anchors.centerIn: parent
            implicitWidth: tacCenterRow.implicitWidth
            implicitHeight: tacCenterRow.implicitHeight

            RowLayout {
                id: tacCenterRow
                anchors.fill: parent
                spacing: 8

                Text {
                    text: "SYS.TIME // " + root.timeStr
                    font.family: "JetBrains Mono"
                    font.weight: Font.Bold
                    font.pixelSize: 11
                    color: tacMa.containsMouse ? theme.accent : "#ffffff"
                }

                Text {
                    text: "• " + root.dateStr + " • " + root.weatherDisplay
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    color: theme.subtext0
                }
            }

            MouseArea {
                id: tacMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellBridge.toggleHud()
            }
        }

        // Right Section: Tactical System Readings
        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Text {
                text: "VOL:" + root.volNumber + "%"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                color: root.isMuted ? theme.red : theme.blue

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onWheel: wheel => {
                        if (!root.sinkAudio) return;
                        let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                        root.sinkAudio.volume = Math.max(0.0, Math.min(1.0, root.sinkAudio.volume + delta));
                    }
                }
            }

            Text {
                text: "[SET]"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                color: theme.mauve
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellBridge.toggleSettings()
                }
            }

            Text {
                text: "[PWR]"
                font.family: "JetBrains Mono"
                font.bold: true
                font.pixelSize: 10
                color: theme.red
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellBridge.togglePower()
                }
            }
        }
    }
}
