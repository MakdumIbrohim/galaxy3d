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
    readonly property string volIcon: isMuted || volNumber === 0 ? "󰝟" : (volNumber < 50 ? "󰖀" : "󰕾")

    readonly property MprisPlayer activePlayer: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    property string timeStr: "00:00:00"
    property string dateStr: "Monday, Nov 16"
    property string weatherDisplay: "30°"
    property string weatherIcon: "󰖐"

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            root.timeStr = Qt.formatTime(d, "HH:mm:ss");
            root.dateStr = Qt.formatDate(d, "dddd, MMM dd");
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
                    root.weatherIcon = lines[0];
                    root.weatherDisplay = lines[1];
                }
            }
        }
    }

    Timer {
        interval: 600000; running: true; repeat: true
        onTriggered: { weatherPoller.running = false; weatherPoller.running = true; }
    }

    // ==========================================
    // 1. LEFT ISLAND: Navigation, Workspaces, Media
    // ==========================================
    Rectangle {
        id: leftIsland
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: 38
        implicitWidth: leftRow.implicitWidth + 24
        radius: 12
        color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.82)
        border.color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.32)
        border.width: 1.2

        RowLayout {
            id: leftRow
            anchors.centerIn: parent
            spacing: 10

            // Launcher Button
            Item {
                width: 26; height: 26
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 18
                    color: distroMouse.containsMouse ? theme.teal : theme.blue
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: distroMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) ShellBridge.toggleSettings();
                        else ShellBridge.toggleLauncher();
                    }
                }
            }

            Rectangle { width: 1; height: 16; color: Qt.rgba(1, 1, 1, 0.15) }

            // Workspaces Cluster
            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: 5
                    delegate: Rectangle {
                        id: wsItem
                        readonly property int wsId: index + 1
                        readonly property bool isCurrent: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                        readonly property bool isOccupied: {
                            const list = Hyprland.workspaces.values;
                            for (let i = 0; i < list.length; i++) {
                                if (list[i].id === wsId) return true;
                            }
                            return false;
                        }

                        width: isCurrent ? 24 : (isOccupied ? 12 : 7)
                        height: 7
                        radius: 3.5
                        color: isCurrent
                            ? theme.mauve
                            : (isOccupied ? Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.55) : Qt.rgba(1, 1, 1, 0.18))

                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", wsItem.wsId.toString()])
                        }
                    }
                }
            }

            // Media Player Snippet (Visible when media is available)
            Rectangle {
                visible: root.activePlayer !== null
                width: 1; height: 16
                color: Qt.rgba(1, 1, 1, 0.15)
            }

            RowLayout {
                id: mediaSnippet
                visible: root.activePlayer !== null
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                // Album Art / Fallback Icon
                Rectangle {
                    width: 22; height: 22; radius: 6
                    color: theme.surface0
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.activePlayer && root.activePlayer.trackArtUrl ? root.activePlayer.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 11
                        color: theme.blue
                        visible: !root.activePlayer || !root.activePlayer.trackArtUrl
                    }
                }

                // Audio visualizer bars (animated when playing)
                Row {
                    spacing: 2
                    visible: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing

                    Repeater {
                        model: 3
                        Rectangle {
                            width: 2.5
                            height: 6 + (index === 1 ? 7 : 4)
                            radius: 1.2
                            color: theme.teal
                            SequentialAnimation on height {
                                loops: Animation.Infinite
                                running: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing
                                NumberAnimation { from: 4; to: 13; duration: 250 + index * 90; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 13; to: 4; duration: 250 + index * 90; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }

                // Track Title (Strictly clipped with max width 165px to prevent center collision)
                Text {
                    text: {
                        if (!root.activePlayer) return "";
                        let title = root.activePlayer.trackTitle || "Media";
                        let artist = root.activePlayer.trackArtist ? (" • " + root.activePlayer.trackArtist) : "";
                        return title + artist;
                    }
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: theme.text
                    elide: Text.ElideRight
                    Layout.maximumWidth: 165
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellBridge.toggleMedia()
                    }
                }

                // Play / Pause Toggle
                Text {
                    text: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 12
                    color: playMa.containsMouse ? theme.teal : theme.blue
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: playMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. CENTER ISLAND: Time, Date & Weather
    // ==========================================
    Rectangle {
        id: centerIsland
        anchors.centerIn: parent
        height: 38
        implicitWidth: centerRow.implicitWidth + 28
        radius: 12
        color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.82)
        border.color: clockMa.containsMouse ? theme.accent : Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.32)
        border.width: 1.2

        MouseArea {
            id: clockMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellBridge.toggleHud()
        }

        RowLayout {
            id: centerRow
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: root.timeStr
                font.family: "JetBrains Mono"
                font.weight: Font.Black
                font.pixelSize: 13
                color: "#ffffff"
            }

            Rectangle { width: 3; height: 3; radius: 1.5; color: theme.teal }

            Text {
                text: root.dateStr
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                color: theme.subtext0
            }

            Rectangle { width: 3; height: 3; radius: 1.5; color: theme.mauve }

            Text {
                text: root.weatherIcon + " " + root.weatherDisplay
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: theme.yellow
            }
        }
    }

    // ==========================================
    // 3. RIGHT ISLAND: Unified System Telemetry Deck
    // ==========================================
    Rectangle {
        id: rightIsland
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 38
        implicitWidth: rightRow.implicitWidth + 24
        radius: 12
        color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.82)
        border.color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.32)
        border.width: 1.2

        RowLayout {
            id: rightRow
            anchors.centerIn: parent
            spacing: 10

            // Volume Section
            Item {
                implicitWidth: volRow.implicitWidth
                implicitHeight: volRow.implicitHeight
                RowLayout {
                    id: volRow
                    anchors.fill: parent
                    spacing: 5
                    Text {
                        text: root.volIcon
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 13
                        color: root.isMuted ? theme.red : theme.blue
                    }
                    Text {
                        text: root.volNumber + "%"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: theme.text
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

            Rectangle { width: 1; height: 16; color: Qt.rgba(1, 1, 1, 0.15) }

            // Settings Trigger
            Text {
                text: ""
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 14
                color: setMa.containsMouse ? theme.mauve : theme.subtext0
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    id: setMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellBridge.toggleSettings()
                }
            }

            // Screenshot Trigger
            Text {
                text: ""
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 13
                color: snapMa.containsMouse ? theme.teal : theme.subtext0
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    id: snapMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) Quickshell.execDetached(["take-screenshot", "region"]);
                        else Quickshell.execDetached(["take-screenshot"]);
                    }
                }
            }

            Rectangle { width: 1; height: 16; color: Qt.rgba(1, 1, 1, 0.15) }

            // Power / Session Button
            Text {
                text: ""
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 13
                color: pwrMa.containsMouse ? theme.red : Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.75)
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    id: pwrMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellBridge.togglePower()
                }
            }
        }
    }
}
