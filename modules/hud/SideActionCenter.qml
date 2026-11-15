import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../../theme"
import "../../services"

PanelWindow {
    id: hudWindow
    visible: false

    WlrLayershell.namespace: "galaxy3d-flight-hud"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: hudWindow.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        right: true
        left: true
    }

    MatugenColors { id: theme }
    Caching { id: paths }

    // Telemetry Properties
    property int cpuPercent: 12
    property int ramPercent: 45
    property string ramText: "7.2 / 16.0 GB"
    property int diskPercent: 35
    property string tempText: "46°C"

    // Weather Properties
    property string weatherTemp: "30°C"
    property string weatherFeels: "36°C"
    property string weatherHumidity: "75%"
    property string weatherWind: "4.8 m/s"
    property string weatherIcon: "󰖗"
    property var hourlyForecast: []

    // Time properties
    property string timeStr: "00:00:00"
    property string dateStr: "Monday, Nov 16"

    Timer {
        interval: 1000
        running: hudWindow.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            hudWindow.timeStr = Qt.formatTime(d, "hh:mm:ss");
            hudWindow.dateStr = Qt.formatDate(d, "dddd, MMMM d");
        }
    }

    // Hardware Telemetry Poller
    Process {
        id: telePoller
        running: hudWindow.visible
        command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print int($2 + $4)}' ; free -m | awk 'NR==2{printf \"%d %0.1f / %0.1f GB\", int($3*100/$2), $3/1024, $2/1024}' ; df -h / | awk 'NR==2{print int($5)}' ; cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print int($1/1000) \"°C\"}' || echo '45°C'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines[0]) hudWindow.cpuPercent = parseInt(lines[0]) || 10;
                if (lines[1]) {
                    let parts = lines[1].split(" ");
                    hudWindow.ramPercent = parseInt(parts[0]) || 40;
                    hudWindow.ramText = parts.slice(1).join(" ") || "7.2 GB";
                }
                if (lines[2]) hudWindow.diskPercent = parseInt(lines[2]) || 30;
                if (lines[3]) hudWindow.tempText = lines[3].trim() || "45°C";
            }
        }
    }

    Timer {
        interval: 3000
        running: hudWindow.visible
        repeat: true
        onTriggered: {
            telePoller.running = false;
            telePoller.running = true;
        }
    }

    // Weather Poller
    Process {
        id: weatherPoller
        running: hudWindow.visible
        command: [paths.qsDir + "/services/galaxy3d-helper", "weather"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    if (data && data.current) {
                        hudWindow.weatherTemp = data.current.temp + "°C";
                        hudWindow.weatherIcon = data.current.icon || "󰖐";
                    }
                    if (data && data.forecast && data.forecast[0]) {
                        let f = data.forecast[0];
                        hudWindow.weatherFeels = f.feels_like + "°C";
                        hudWindow.weatherHumidity = f.humidity + "%";
                        hudWindow.weatherWind = f.wind + " m/s";
                        hudWindow.hourlyForecast = f.hourly || [];
                    }
                } catch (e) {}
            }
        }
    }

    // Media Tracker
    readonly property var activePlayer: (Mpris.players && Mpris.players.values && Mpris.players.values.length > 0)
        ? Mpris.players.values[0]
        : null

    // Backdrop dismissal
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.03, 0.06, 0.6)
        opacity: hudWindow.visible ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: hudWindow.visible = false
        }
    }

    // HUD Side Panel
    Rectangle {
        id: hudPanel
        width: Math.min(450, parent.width - 20)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.95)
        border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.45)
        border.width: 1.5
        clip: true

        transform: Translate {
            x: hudWindow.visible ? 0 : hudPanel.width
            Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // ========================================================
            // HUD HEADER
            // ========================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 38; height: 38; radius: 10
                    color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2)
                    border.color: theme.accent
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰄛"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 18
                        color: theme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    RowLayout {
                        spacing: 6
                        Text {
                            text: "FLIGHT CONTROL HUD"
                            font.family: "JetBrains Mono"
                            font.bold: true
                            font.pixelSize: 13
                            color: theme.text
                        }
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: "#a6e3a1"
                        }
                    }
                    Text {
                        text: "ORBITAL TELEMETRY & SYSTEM DECK"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 8
                        color: theme.overlay0
                    }
                }

                Rectangle {
                    width: 34; height: 34; radius: 8
                    color: closeHudMa.containsMouse ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.25) : theme.surface0
                    border.color: closeHudMa.containsMouse ? theme.red : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 14
                        color: closeHudMa.containsMouse ? theme.red : theme.subtext0
                    }

                    MouseArea {
                        id: closeHudMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: hudWindow.visible = false
                    }
                }
            }

            Rectangle {
                height: 1
                Layout.fillWidth: true
                color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.45)
            }

            // Scrollable Content
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: parent.width - 12
                    spacing: 16

                    // ================================================
                    // 1. HARDWARE TELEMETRY GAUGES
                    // ================================================
                    Text {
                        text: "CORE TELEMETRY GAUGES"
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 10
                        color: theme.subtext0
                    }

                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true
                        rowSpacing: 10
                        columnSpacing: 10

                        // CPU Gauge Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 68
                            radius: 12
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "󰻠 CPU Load"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 10; color: theme.text; Layout.fillWidth: true }
                                    Text { text: hudWindow.cpuPercent + "%"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 11; color: theme.blue }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: theme.mantle
                                    Rectangle {
                                        width: parent.width * (Math.max(0, Math.min(100, hudWindow.cpuPercent)) / 100.0)
                                        height: parent.height
                                        radius: parent.radius
                                        color: theme.blue
                                    }
                                }
                            }
                        }

                        // RAM Gauge Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 68
                            radius: 12
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "󰍛 Memory"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 10; color: theme.text; Layout.fillWidth: true }
                                    Text { text: hudWindow.ramPercent + "%"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 11; color: theme.mauve }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: theme.mantle
                                    Rectangle {
                                        width: parent.width * (Math.max(0, Math.min(100, hudWindow.ramPercent)) / 100.0)
                                        height: parent.height
                                        radius: parent.radius
                                        color: theme.mauve
                                    }
                                }

                                Text { text: hudWindow.ramText; font.family: "JetBrains Mono"; font.pixelSize: 8; color: theme.overlay0 }
                            }
                        }

                        // Disk Storage Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 68
                            radius: 12
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "󰋊 Root Disk"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 10; color: theme.text; Layout.fillWidth: true }
                                    Text { text: hudWindow.diskPercent + "%"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 11; color: theme.teal }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: theme.mantle
                                    Rectangle {
                                        width: parent.width * (Math.max(0, Math.min(100, hudWindow.diskPercent)) / 100.0)
                                        height: parent.height
                                        radius: parent.radius
                                        color: theme.teal
                                    }
                                }
                            }
                        }

                        // Thermal Zone Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 68
                            radius: 12
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "󰔏 Core Thermal"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 10; color: theme.text; Layout.fillWidth: true }
                                    Text { text: hudWindow.tempText; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 11; color: theme.peach }
                                }

                                Text { text: "Cooling status optimal"; font.family: "JetBrains Mono"; font.pixelSize: 8; color: theme.overlay0 }
                            }
                        }
                    }

                    // ================================================
                    // 2. QUICK TOGGLES MATRIX (2x3)
                    // ================================================
                    Text {
                        text: "ORBITAL QUICK TOGGLES"
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 10
                        color: theme.subtext0
                    }

                    GridLayout {
                        columns: 3
                        Layout.fillWidth: true
                        rowSpacing: 8
                        columnSpacing: 8

                        // 1. Night Light Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 10
                            color: ShellBridge.nightLightEnabled ? Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.22) : theme.surface0
                            border.color: ShellBridge.nightLightEnabled ? theme.peach : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { Layout.alignment: Qt.AlignHCenter; text: "󰖔"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: ShellBridge.nightLightEnabled ? theme.peach : theme.subtext0 }
                                Text { Layout.alignment: Qt.AlignHCenter; text: "Night Light"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: ShellBridge.nightLightEnabled; color: theme.text }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ShellBridge.setNightLight(!ShellBridge.nightLightEnabled, ShellBridge.nightLightTemp)
                            }
                        }

                        // 2. Do Not Disturb Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 10
                            color: ShellBridge.dndEnabled ? Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.22) : theme.surface0
                            border.color: ShellBridge.dndEnabled ? theme.mauve : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { Layout.alignment: Qt.AlignHCenter; text: "󰂛"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: ShellBridge.dndEnabled ? theme.mauve : theme.subtext0 }
                                Text { Layout.alignment: Qt.AlignHCenter; text: "DND Mode"; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: ShellBridge.dndEnabled; color: theme.text }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ShellBridge.setDnd(!ShellBridge.dndEnabled)
                            }
                        }

                        // 3. Screenshot Capture
                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 10
                            color: snapMa.containsMouse ? Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.25) : theme.surface0
                            border.color: snapMa.containsMouse ? theme.teal : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { Layout.alignment: Qt.AlignHCenter; text: "󰹑"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: theme.teal }
                                Text { Layout.alignment: Qt.AlignHCenter; text: "Screenshot"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.text }
                            }

                            MouseArea {
                                id: snapMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    hudWindow.visible = false;
                                    Quickshell.execDetached(["bash", "-c", "sleep 0.3 && grim -g \"$(slurp)\" - | wl-copy && notify-send 'Screenshot' 'Copied to clipboard'"]);
                                }
                            }
                        }

                        // 4. Wi-Fi Radar Panel
                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 10
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { Layout.alignment: Qt.AlignHCenter; text: "󰤨"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: theme.blue }
                                Text { Layout.alignment: Qt.AlignHCenter; text: "Radar Scan"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.text }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    hudWindow.visible = false;
                                    ShellBridge.openNetwork();
                                }
                            }
                        }

                        // 5. App Launcher
                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 10
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { Layout.alignment: Qt.AlignHCenter; text: "󰕰"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: theme.green }
                                Text { Layout.alignment: Qt.AlignHCenter; text: "Launcher"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.text }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    hudWindow.visible = false;
                                    ShellBridge.openLauncher();
                                }
                            }
                        }

                        // 6. Settings Deck
                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 10
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text { Layout.alignment: Qt.AlignHCenter; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: theme.accent }
                                Text { Layout.alignment: Qt.AlignHCenter; text: "Settings"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.text }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    hudWindow.visible = false;
                                    ShellBridge.openSettings();
                                }
                            }
                        }
                    }

                    // ================================================
                    // 3. ORBITAL WEATHER FORECAST
                    // ================================================
                    Text {
                        text: "ORBITAL WEATHER TELEMETRY"
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 10
                        color: theme.subtext0
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 110
                        radius: 14
                        color: theme.surface0
                        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Text {
                                    text: hudWindow.weatherIcon
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 28
                                    color: theme.blue
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text { text: hudWindow.weatherTemp; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 17; color: theme.text }
                                    Text { text: "Feels like: " + hudWindow.weatherFeels; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.subtext0 }
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Text { text: "Humidity: " + hudWindow.weatherHumidity; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.overlay0 }
                                    Text { text: "Wind: " + hudWindow.weatherWind; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.overlay0 }
                                }
                            }

                            // Hourly forecast row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: (hudWindow.hourlyForecast && hudWindow.hourlyForecast.slice) ? hudWindow.hourlyForecast.slice(0, 5) : 0

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 38
                                        radius: 6
                                        color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.6)

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 1
                                            Text { Layout.alignment: Qt.AlignHCenter; text: modelData.time || ""; font.family: "JetBrains Mono"; font.pixelSize: 7; color: theme.overlay0 }
                                            Text { Layout.alignment: Qt.AlignHCenter; text: (modelData.temp || "") + "°"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 9; color: theme.text }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ================================================
                    // 4. ACTIVE MEDIA PLAYBACK
                    // ================================================
                    Text {
                        text: "ACTIVE MEDIA STREAM"
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 10
                        color: theme.subtext0
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 72
                        radius: 12
                        color: theme.surface0
                        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Rectangle {
                                width: 44; height: 44; radius: 8
                                color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.22)
                                border.color: theme.accent
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰝚"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 20
                                    color: theme.accent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: (hudWindow.activePlayer && hudWindow.activePlayer.trackTitle)
                                        ? hudWindow.activePlayer.trackTitle
                                        : "No Orbital Stream Active"
                                    font.family: "JetBrains Mono"
                                    font.bold: true
                                    font.pixelSize: 11
                                    color: theme.text
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: (hudWindow.activePlayer && hudWindow.activePlayer.trackArtist)
                                        ? hudWindow.activePlayer.trackArtist
                                        : "Mpris Player Idle"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 9
                                    color: theme.subtext0
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Media Controls
                            RowLayout {
                                spacing: 6

                                Rectangle {
                                    width: 30; height: 30; radius: 6
                                    color: theme.surface1
                                    Text { anchors.centerIn: parent; text: "󰒮"; font.family: "Iosevka Nerd Font"; font.pixelSize: 12; color: theme.text }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (hudWindow.activePlayer) hudWindow.activePlayer.previous()
                                    }
                                }

                                Rectangle {
                                    width: 32; height: 32; radius: 16
                                    color: theme.accent
                                    Text {
                                        anchors.centerIn: parent
                                        text: (hudWindow.activePlayer && hudWindow.activePlayer.isPlaying) ? "󰏤" : "󰐊"
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: theme.crust
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (hudWindow.activePlayer) hudWindow.activePlayer.togglePlaying()
                                    }
                                }

                                Rectangle {
                                    width: 30; height: 30; radius: 6
                                    color: theme.surface1
                                    Text { anchors.centerIn: parent; text: "󰒭"; font.family: "Iosevka Nerd Font"; font.pixelSize: 12; color: theme.text }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (hudWindow.activePlayer) hudWindow.activePlayer.next()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
