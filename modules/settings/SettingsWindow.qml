import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../../theme"
import "../../services"
import "views"
import "tabs"

PanelWindow {
    id: settingsWindow
    visible: false

    WlrLayershell.namespace: "galaxy3d-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: settingsWindow.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MatugenColors { id: theme }
    Caching { id: paths }

    property int activeCategoryIndex: 0
    readonly property var categories: [
        { "name": "Appearance",     "icon": "󰔎", "desc": "Wallpaper, theme modes, accents, and TopBar HUD style" },
        { "name": "Network",        "icon": "󰤨", "desc": "Orbital telemetry, Wi-Fi scanner, and radio locks" },
        { "name": "Sound",          "icon": "󰕾", "desc": "Master sink & source audio levels and devices" },
        { "name": "Notifications",  "icon": "󰂚", "desc": "Notification daemon popups and Do Not Disturb" },
        { "name": "Bluetooth",      "icon": "󰂯", "desc": "Wireless radio power and device pairing status" },
        { "name": "Privacy",        "icon": "󰒃", "desc": "Location telemetry and session security" },
        { "name": "Accounts",       "icon": "󰀉", "desc": "Active session profile and user credentials" },
        { "name": "System",         "icon": "󰋽", "desc": "OS telemetry, kernel specs, and repository updates" }
    ]

    property bool isBtPowered: false
    property bool isAirplaneMode: false

    // Hardware status pollers
    Process {
        id: btStatusPoller
        running: settingsWindow.visible
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'"]
        stdout: StdioCollector {
            onStreamFinished: settingsWindow.isBtPowered = (this.text.trim() === "1")
        }
    }

    Process {
        id: rfkillPoller
        running: settingsWindow.visible
        command: ["bash", "-c", "rfkill list all 2>/dev/null | grep -q 'Soft blocked: yes' && echo '1' || echo '0'"]
        stdout: StdioCollector {
            onStreamFinished: settingsWindow.isAirplaneMode = (this.text.trim() === "1")
        }
    }

    Process {
        id: updateChecker
        command: ["bash", "-c", "COUNT=$(checkupdates 2>/dev/null | wc -l) ; if [ \"$COUNT\" -gt 0 ]; then notify-send -u normal -i software-update-available 'System Updates' \"$COUNT packages ready to update\" ; else notify-send -i checkbox-checked 'System Updates' 'System is up to date' ; fi"]
    }

    // Pipewire Audio Trackers
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].filter(n => n)
    }
    readonly property var sinkAudio: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio : null
    readonly property var sourceAudio: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) ? Pipewire.defaultAudioSource.audio : null

    // System Telemetry
    property string osName: "CachyOS Linux (x86_64)"
    property string kernelVer: "Linux 6.x"
    property string uptimeStr: "Up 2 hours"
    property string diskUsageStr: "34GB / 256GB"

    Process {
        id: sysInfoReader
        running: settingsWindow.visible
        command: ["bash", "-c", "uname -sr ; uptime -p ; df -h / | awk 'NR==2 {print $3 \" / \" $2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 1) settingsWindow.kernelVer = lines[0];
                if (lines.length >= 2) settingsWindow.uptimeStr = lines[1];
                if (lines.length >= 3) settingsWindow.diskUsageStr = lines[2];
            }
        }
    }

    // Backdrop with smooth fade
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0.03, 0.04, 0.08, 0.72)
        opacity: settingsWindow.visible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: settingsWindow.visible = false
        }
    }

    // Main Settings Card
    Rectangle {
        id: settingsCard
        width: Math.min(960, parent.width - 40)
        height: Math.min(680, parent.height - 40)
        anchors.centerIn: parent
        radius: 20
        color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.95)
        border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.45)
        border.width: 1.5
        clip: true

        scale: settingsWindow.visible ? 1.0 : 0.94
        opacity: settingsWindow.visible ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Glowing Top Edge Accent
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: theme.accent
            opacity: 0.8
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // 1. Left Sidebar Navigation
            SettingsSidebar {
                Layout.fillHeight: true
                Layout.preferredWidth: 240
                theme: theme
                categories: settingsWindow.categories
                activeCategoryIndex: settingsWindow.activeCategoryIndex
                onCategorySelected: function(idx) { settingsWindow.activeCategoryIndex = idx; }
                onCloseRequested: settingsWindow.visible = false
            }

            // Vertical Divider
            Rectangle {
                width: 1
                Layout.fillHeight: true
                color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.45)
            }

            // 2. Right Content Pane
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                anchors.margins: 22
                spacing: 16

                // Category Header Deck
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 44; height: 44; radius: 12
                        color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.16)
                        border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.35)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: settingsWindow.categories[settingsWindow.activeCategoryIndex].icon
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 22
                            color: theme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: settingsWindow.categories[settingsWindow.activeCategoryIndex].name
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: 16
                            color: theme.text
                        }
                        Text {
                            text: settingsWindow.categories[settingsWindow.activeCategoryIndex].desc
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            color: theme.subtext0
                        }
                    }

                    Rectangle {
                        height: 24; width: 86; radius: 12
                        color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.5)
                        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "SYS DECK"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            font.bold: true
                            color: theme.overlay0
                        }
                    }
                }

                Rectangle {
                    height: 1
                    Layout.fillWidth: true
                    color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.35)
                }

                // Scrollable Content Panes
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    AppearanceTab {
                        visible: settingsWindow.activeCategoryIndex === 0
                        width: parent.width - 16
                        theme: theme
                        paths: paths
                    }

                    NetworkTab {
                        visible: settingsWindow.activeCategoryIndex === 1
                        width: parent.width - 16
                        theme: theme
                        isAirplaneMode: settingsWindow.isAirplaneMode
                        onCloseSettingsRequested: settingsWindow.visible = false
                    }

                    SoundTab {
                        visible: settingsWindow.activeCategoryIndex === 2
                        width: parent.width - 16
                        theme: theme
                        sinkAudio: settingsWindow.sinkAudio
                        sourceAudio: settingsWindow.sourceAudio
                    }

                    NotificationsTab {
                        visible: settingsWindow.activeCategoryIndex === 3
                        width: parent.width - 16
                        theme: theme
                    }

                    BluetoothTab {
                        visible: settingsWindow.activeCategoryIndex === 4
                        width: parent.width - 16
                        theme: theme
                        isBtPowered: settingsWindow.isBtPowered
                    }

                    PrivacyTab {
                        visible: settingsWindow.activeCategoryIndex === 5
                        width: parent.width - 16
                        theme: theme
                    }

                    AccountsTab {
                        visible: settingsWindow.activeCategoryIndex === 6
                        width: parent.width - 16
                        theme: theme
                    }

                    SystemTab {
                        visible: settingsWindow.activeCategoryIndex === 7
                        width: parent.width - 16
                        theme: theme
                        osName: settingsWindow.osName
                        kernelVer: settingsWindow.kernelVer
                        uptimeStr: settingsWindow.uptimeStr
                        diskUsageStr: settingsWindow.diskUsageStr
                        onUpdateCheckRequested: {
                            Quickshell.execDetached(["notify-send", "System Updates", "Checking package repositories..."]);
                            updateChecker.running = false;
                            updateChecker.running = true;
                        }
                    }
                }
            }
        }
    }
}
