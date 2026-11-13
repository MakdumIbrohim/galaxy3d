import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Hyprland

PanelWindow {
    id: topBarWin

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 46
    WlrLayershell.namespace: "galaxy3d-topbar"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Auto
    color: "transparent"

    readonly property MprisPlayer activePlayer: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 4
        anchors.bottomMargin: 4

        // SISI KIRI: Distro Icon + Workspaces + Spotify Media Pill
        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Logo CachyOS Pill
            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: Qt.rgba(0.08, 0.08, 0.12, 0.85)
                border.color: Qt.rgba(1, 1, 1, 0.15)
                border.width: 1

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: "/usr/share/icons/cachyos.svg"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["qs", "-c", "galaxy3d", "ipc", "call", "launcher", "toggle"])
                }
            }

            // Workspace Dots
            Rectangle {
                height: 34
                implicitWidth: wsRow.implicitWidth + 18
                radius: 17
                color: Qt.rgba(0.08, 0.08, 0.12, 0.85)
                border.color: Qt.rgba(1, 1, 1, 0.15)
                border.width: 1

                RowLayout {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: 7

                    Repeater {
                        model: 5
                        Rectangle {
                            readonly property int wsId: index + 1
                            readonly property bool isCurrent: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                            width: isCurrent ? 22 : 8
                            height: 8
                            radius: 4
                            color: isCurrent ? "#89b4fa" : Qt.rgba(1, 1, 1, 0.3)
                            Behavior on width { NumberAnimation { duration: 200 } }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("workspace " + wsId)
                            }
                        }
                    }
                }
            }

            // Spotify / Media Player Pill (persis seperti di gambar)
            Rectangle {
                id: mediaPill
                height: 34
                implicitWidth: Math.min(280, mediaLayout.implicitWidth + 22)
                radius: 17
                color: Qt.rgba(0.08, 0.08, 0.12, 0.85)
                border.color: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? Qt.rgba(0.54, 0.71, 0.98, 0.4) : Qt.rgba(1, 1, 1, 0.15)
                border.width: 1
                visible: activePlayer !== null

                RowLayout {
                    id: mediaLayout
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    // Album Art / Music Icon
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: "#181825"
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: activePlayer && activePlayer.trackArtUrl ? activePlayer.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 11
                            color: "#89b4fa"
                            visible: !activePlayer || !activePlayer.trackArtUrl
                        }
                    }

                    // Track Title & Artist
                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (!activePlayer) return "No Media";
                            const title = activePlayer.trackTitle || "Unknown Track";
                            const artist = activePlayer.trackArtist ? (" - " + activePlayer.trackArtist) : "";
                            return title + artist;
                        }
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: "#cdd6f4"
                        elide: Text.ElideRight
                    }

                    // Play/Pause Button
                    Text {
                        text: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 13
                        color: "#89b4fa"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (activePlayer) activePlayer.togglePlaying()
                        }
                    }

                    // Next Button
                    Text {
                        text: "󰒭"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 12
                        color: Qt.rgba(1, 1, 1, 0.6)

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (activePlayer) activePlayer.next()
                        }
                    }
                }
            }
        }

        // SISI TENGAH: Time, Date & Weather Pill
        Rectangle {
            anchors.centerIn: parent
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

        // SISI KANAN: System Controls (Lang, Wifi, Volume, Battery, Power)
        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Volume Pill
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

            // Screenshot Tool Button
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

            // Battery Pill
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
    }
}
