import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../../theme"
import "../../services"

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

    // ========================================================
    // CUSTOM SCI-FI CONTROLS
    // ========================================================
    component SciFiSwitch: Rectangle {
        id: switchRoot
        property bool checked: false
        signal toggled(bool newState)

        width: 46
        height: 24
        radius: 12
        color: checked ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.45) : theme.surface1
        border.color: checked ? theme.accent : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.6)
        border.width: 1.5

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Rectangle {
            id: thumb
            width: 18
            height: 18
            radius: 9
            y: 3
            x: switchRoot.checked ? switchRoot.width - width - 3 : 3
            color: switchRoot.checked ? theme.accent : theme.subtext0

            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                switchRoot.checked = !switchRoot.checked;
                switchRoot.toggled(switchRoot.checked);
            }
        }
    }

    component SciFiSlider: Item {
        id: sliderRoot
        property real from: 0.0
        property real to: 1.0
        property real value: 0.5
        property color trackColor: theme.accent
        signal moved(real val)

        implicitWidth: 200
        implicitHeight: 26

        readonly property real range: Math.max(0.0001, to - from)
        readonly property real normalized: Math.max(0.0, Math.min(1.0, (value - from) / range))

        Rectangle {
            id: trackBg
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 7
            radius: 3.5
            color: theme.surface1

            Rectangle {
                width: parent.width * sliderRoot.normalized
                height: parent.height
                radius: parent.radius
                color: sliderRoot.trackColor
            }
        }

        Rectangle {
            id: handle
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(sliderRoot.width - width, (sliderRoot.width - width) * sliderRoot.normalized))
            color: "#ffffff"
            border.color: sliderRoot.trackColor
            border.width: 2.5
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            function updateVal(mouseX) {
                var frac = Math.max(0.0, Math.min(1.0, mouseX / sliderRoot.width));
                var newVal = sliderRoot.from + frac * sliderRoot.range;
                sliderRoot.value = newVal;
                sliderRoot.moved(newVal);
            }

            onPressed: function(mouse) { updateVal(mouse.x); }
            onPositionChanged: function(mouse) {
                if (pressed) updateVal(mouse.x);
            }
        }
    }

    // ========================================================
    // BACKDROP WITH SMOOTH FADE
    // ========================================================
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

    // ========================================================
    // MAIN SETTINGS CARD CONTAINER
    // ========================================================
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

            // ========================================================
            // LEFT SIDEBAR (Category Navigation)
            // ========================================================
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 240
                color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.75)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Sidebar Brand Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 10
                            color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.18)
                            border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.4)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: ""
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
                                    text: "CONTROL DECK"
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    font.pixelSize: 12
                                    color: theme.text
                                }
                                Rectangle {
                                    width: 6; height: 6; radius: 3
                                    color: "#a6e3a1"
                                }
                            }

                            Text {
                                text: "GALAXY // SYSTEM PREFS"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8
                                color: theme.overlay0
                            }
                        }
                    }

                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.5)
                    }

                    // Category List
                    ListView {
                        id: catListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: settingsWindow.categories
                        spacing: 4
                        clip: true

                        delegate: Rectangle {
                            readonly property bool isSelected: settingsWindow.activeCategoryIndex === index
                            width: catListView.width
                            height: 42
                            radius: 10
                            color: isSelected
                                ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.18)
                                : (catMa.containsMouse ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.45) : "transparent")
                            border.color: isSelected
                                ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.5)
                                : "transparent"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 12
                                spacing: 10

                                // Active left vertical pill indicator
                                Rectangle {
                                    width: 3.5
                                    height: 18
                                    radius: 2
                                    color: isSelected ? theme.accent : "transparent"
                                }

                                Text {
                                    text: modelData.icon
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 15
                                    color: isSelected ? theme.accent : theme.subtext0
                                }

                                Text {
                                    text: modelData.name
                                    font.family: "JetBrains Mono"
                                    font.weight: isSelected ? Font.Bold : Font.Normal
                                    font.pixelSize: 11
                                    color: isSelected ? theme.text : theme.subtext0
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: catMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsWindow.activeCategoryIndex = index
                            }
                        }
                    }

                    // Bottom Close Settings Button
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 10
                        color: sidebarCloseMa.containsMouse
                            ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.22)
                            : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.6)
                        border.color: sidebarCloseMa.containsMouse
                            ? theme.red
                            : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: "󰅖"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 14
                                color: sidebarCloseMa.containsMouse ? theme.red : theme.subtext0
                            }
                            Text {
                                text: "Close Settings"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 11
                                font.bold: true
                                color: sidebarCloseMa.containsMouse ? theme.text : theme.subtext0
                            }
                        }

                        MouseArea {
                            id: sidebarCloseMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsWindow.visible = false
                        }
                    }
                }
            }

            // Vertical Divider
            Rectangle {
                width: 1
                Layout.fillHeight: true
                color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.45)
            }

            // ========================================================
            // RIGHT CONTENT PANE
            // ========================================================
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
                        width: 44
                        height: 44
                        radius: 12
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

                    // Live Config Badge
                    Rectangle {
                        height: 24
                        width: 86
                        radius: 12
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

                // Scrollable Content Views
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // --------------------------------------------------------
                    // 1. APPEARANCE
                    // --------------------------------------------------------
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 0
                        width: parent.width - 16
                        spacing: 16

                        // Wallpaper Header
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "DESKTOP WALLPAPER"
                                font.family: "JetBrains Mono"
                                font.bold: true
                                font.pixelSize: 11
                                color: theme.subtext0
                                Layout.fillWidth: true
                            }
                            Text {
                                text: ShellBridge.currentWallpaper !== ""
                                    ? ShellBridge.currentWallpaper.substring(ShellBridge.currentWallpaper.lastIndexOf("/") + 1)
                                    : "Default"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                color: theme.overlay0
                            }
                        }

                        // Preset Wallpapers Row
                        RowLayout {
                            spacing: 14

                            Repeater {
                                model: [
                                    { "name": "Cosmic Galaxy", "file": "/usr/share/wallpapers/cachyos-wallpapers/cachygalaxy99.jpg" },
                                    { "name": "Lunar Horizon", "file": "/usr/share/wallpapers/cachyos-wallpapers/CachyOS_Moon.jpg" },
                                    { "name": "Emerald Space", "file": "/usr/share/wallpapers/cachyos-wallpapers/CachyOS_GreenSpace.png" }
                                ]

                                delegate: Rectangle {
                                    readonly property bool isSelected: ShellBridge.currentWallpaper === modelData.file
                                    width: 180
                                    height: 102
                                    radius: 12
                                    color: theme.surface0
                                    border.color: isSelected
                                        ? theme.accent
                                        : (selectWpMa.containsMouse ? theme.surface2 : Qt.rgba(1, 1, 1, 0.08))
                                    border.width: isSelected ? 2 : 1
                                    clip: true

                                    scale: selectWpMa.containsMouse ? 1.02 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 150 } }

                                    Image {
                                        anchors.fill: parent
                                        source: "file://" + modelData.file
                                        fillMode: Image.PreserveAspectCrop
                                    }

                                    // Scrim overlay
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: 28
                                        color: Qt.rgba(0, 0, 0, 0.75)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8; anchors.rightMargin: 8
                                            Text {
                                                text: modelData.name
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: 10
                                                font.bold: isSelected
                                                color: isSelected ? theme.accent : "#ffffff"
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }

                                    // Active checkmark badge
                                    Rectangle {
                                        visible: isSelected
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 6
                                        width: 22; height: 22; radius: 11
                                        color: theme.accent

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰄬"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 12
                                            color: theme.crust
                                        }
                                    }

                                    MouseArea {
                                        id: selectWpMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            ShellBridge.setWallpaper(modelData.file);
                                            Quickshell.execDetached(["notify-send", "Wallpaper Updated", modelData.name]);
                                        }
                                    }
                                }
                            }
                        }

                        // Wallpaper Action Buttons
                        RowLayout {
                            spacing: 10

                            Rectangle {
                                height: 32
                                width: 140
                                radius: 8
                                color: randWpMa.containsMouse ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.25) : theme.surface0
                                border.color: randWpMa.containsMouse ? theme.accent : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "󰒝"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: theme.accent }
                                    Text { text: "Randomize"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; color: theme.text }
                                }

                                MouseArea {
                                    id: randWpMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ShellBridge.randomWallpaper()
                                }
                            }

                            Rectangle {
                                height: 32
                                width: 155
                                radius: 8
                                color: customWpMa.containsMouse ? Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.25) : theme.surface0
                                border.color: customWpMa.containsMouse ? theme.teal : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "󰋩"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: theme.teal }
                                    Text { text: "Browse Image..."; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; color: theme.text }
                                }

                                MouseArea {
                                    id: customWpMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["bash", "-c", "FILE=$(zenity --file-selection --title='Select Wallpaper' --file-filter='Images | *.jpg *.png *.jpeg *.webp' 2>/dev/null) ; if [ -n \"$FILE\" ]; then echo \"$FILE\" > " + paths.configDir + "/wallpaper.conf ; notify-send 'Wallpaper Updated' \"$FILE\"; fi"]);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            height: 1
                            Layout.fillWidth: true
                            color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.3)
                        }

                        // Theme Mode & Accent Swatches Card
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            // Base Theme Segmented Control
                            Rectangle {
                                Layout.fillWidth: true
                                height: 82
                                radius: 12
                                color: theme.surface0
                                border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.3)
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    Text {
                                        text: "BASE THEME MODE"
                                        font.family: "JetBrains Mono"
                                        font.bold: true
                                        font.pixelSize: 10
                                        color: theme.subtext0
                                    }

                                    // Segmented Toggle
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 32
                                        radius: 8
                                        color: theme.mantle

                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 0

                                            // Dark Option
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 8
                                                color: ShellBridge.isDarkMode ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.22) : "transparent"
                                                border.color: ShellBridge.isDarkMode ? theme.accent : "transparent"
                                                border.width: 1

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 6
                                                    Text { text: "󰽥"; font.family: "Iosevka Nerd Font"; font.pixelSize: 12; color: ShellBridge.isDarkMode ? theme.accent : theme.subtext0 }
                                                    Text { text: "Dark Mode"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: ShellBridge.isDarkMode; color: ShellBridge.isDarkMode ? theme.text : theme.subtext0 }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        ShellBridge.setDarkMode(true);
                                                        Quickshell.execDetached(["notify-send", "Theme Mode", "Switched to Dark Mode"]);
                                                    }
                                                }
                                            }

                                            // Light Option
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 8
                                                color: !ShellBridge.isDarkMode ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.22) : "transparent"
                                                border.color: !ShellBridge.isDarkMode ? theme.accent : "transparent"
                                                border.width: 1

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 6
                                                    Text { text: "󰖙"; font.family: "Iosevka Nerd Font"; font.pixelSize: 12; color: !ShellBridge.isDarkMode ? theme.accent : theme.subtext0 }
                                                    Text { text: "Light Mode"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: !ShellBridge.isDarkMode; color: !ShellBridge.isDarkMode ? theme.text : theme.subtext0 }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        ShellBridge.setDarkMode(false);
                                                        Quickshell.execDetached(["notify-send", "Theme Mode", "Switched to Light Mode"]);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Accent Palette Card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 82
                                radius: 12
                                color: theme.surface0
                                border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.3)
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "ACCENT PALETTE"
                                            font.family: "JetBrains Mono"
                                            font.bold: true
                                            font.pixelSize: 10
                                            color: theme.subtext0
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: ShellBridge.activeAccent
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: theme.accent
                                        }
                                    }

                                    RowLayout {
                                        spacing: 10

                                        Repeater {
                                            model: [
                                                { "name": "Mauve",    "col": theme.mauve },
                                                { "name": "Blue",     "col": theme.blue },
                                                { "name": "Sapphire", "col": theme.sapphire },
                                                { "name": "Teal",     "col": theme.teal },
                                                { "name": "Peach",    "col": theme.peach },
                                                { "name": "Green",    "col": theme.green },
                                                { "name": "Pink",     "col": theme.pink }
                                            ]

                                            delegate: Rectangle {
                                                readonly property bool isSelected: ShellBridge.activeAccent.toLowerCase() === modelData.name.toLowerCase()
                                                width: 28; height: 28; radius: 14
                                                color: modelData.col
                                                border.color: "#ffffff"
                                                border.width: isSelected ? 2.5 : 0
                                                scale: isSelected ? 1.15 : (swatchMa.containsMouse ? 1.08 : 1.0)

                                                Behavior on scale { NumberAnimation { duration: 150 } }

                                                Text {
                                                    visible: isSelected
                                                    anchors.centerIn: parent
                                                    text: "󰄬"
                                                    font.family: "Iosevka Nerd Font"
                                                    font.pixelSize: 13
                                                    color: "#000000"
                                                }

                                                MouseArea {
                                                    id: swatchMa
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        ShellBridge.setAccent(modelData.name);
                                                        Quickshell.execDetached(["notify-send", "Accent Palette", "Accent color set to " + modelData.name]);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            height: 1
                            Layout.fillWidth: true
                            color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.3)
                        }

                        // TopBar Style Selector
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "TOPBAR HUD STYLE"
                                font.family: "JetBrains Mono"
                                font.bold: true
                                font.pixelSize: 11
                                color: theme.subtext0
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Repeater {
                                    model: [
                                        { id: "cyber",    name: "Cyber Dock",   desc: "3 Floating Glass Islands", icon: "󰕰" },
                                        { id: "tactical", name: "Tactical HUD", desc: "Full-Width Sci-Fi Rail",   icon: "󰄛" },
                                        { id: "capsule",  name: "Capsule",      desc: "Compact Minimalist Pills", icon: "󰝥" }
                                    ]

                                    delegate: Rectangle {
                                        readonly property bool isSelected: ShellBridge.topbarStyle === modelData.id
                                        Layout.fillWidth: true
                                        height: 64
                                        radius: 12
                                        color: isSelected
                                            ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.16)
                                            : (hudMa.containsMouse ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.4) : theme.surface0)
                                        border.color: isSelected
                                            ? theme.accent
                                            : (hudMa.containsMouse ? theme.surface2 : Qt.rgba(1, 1, 1, 0.08))
                                        border.width: isSelected ? 1.5 : 1

                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12; anchors.rightMargin: 12
                                            spacing: 10

                                            Rectangle {
                                                width: 36; height: 36; radius: 8
                                                color: isSelected ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.25) : theme.surface1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.icon
                                                    font.family: "Iosevka Nerd Font"
                                                    font.pixelSize: 16
                                                    color: isSelected ? theme.accent : theme.subtext0
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text {
                                                    text: modelData.name
                                                    font.family: "JetBrains Mono"
                                                    font.weight: isSelected ? Font.Bold : Font.Normal
                                                    font.pixelSize: 11
                                                    color: isSelected ? theme.text : theme.subtext0
                                                }
                                                Text {
                                                    text: modelData.desc
                                                    font.family: "JetBrains Mono"
                                                    font.pixelSize: 8
                                                    color: theme.overlay0
                                                }
                                            }

                                            // Radio selection indicator
                                            Rectangle {
                                                width: 18; height: 18; radius: 9
                                                color: isSelected ? theme.accent : "transparent"
                                                border.color: isSelected ? theme.accent : theme.surface2
                                                border.width: 1.5

                                                Text {
                                                    visible: isSelected
                                                    anchors.centerIn: parent
                                                    text: "󰄬"
                                                    font.family: "Iosevka Nerd Font"
                                                    font.pixelSize: 10
                                                    color: theme.crust
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: hudMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                ShellBridge.setTopbarStyle(modelData.id);
                                                Quickshell.execDetached(["notify-send", "TopBar Style", "HUD set to " + modelData.name]);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // --------------------------------------------------------
                    // 2. NETWORK
                    // --------------------------------------------------------
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 1
                        width: parent.width - 16
                        spacing: 14

                        Text {
                            text: "COMMUNICATION & SATELLITE LINKS"
                            font.family: "JetBrains Mono"
                            font.bold: true
                            font.pixelSize: 11
                            color: theme.subtext0
                        }

                        // Wi-Fi Scanner Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 60
                            radius: 12
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                Text { text: "󰤨"; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: theme.blue }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { text: "Orbital Satellite & Wi-Fi Scanner"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text }
                                    Text { text: "Scan and connect to local wireless access points"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.subtext0 }
                                }

                                Rectangle {
                                    width: 115
                                    height: 32
                                    radius: 8
                                    color: scanBtnMa.containsMouse ? Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.3) : theme.blue

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text { text: "󰑐"; font.family: "Iosevka Nerd Font"; font.pixelSize: 12; color: theme.crust }
                                        Text { text: "Open Radar"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; color: theme.crust }
                                    }

                                    MouseArea {
                                        id: scanBtnMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            settingsWindow.visible = false;
                                            ShellBridge.openNetwork();
                                        }
                                    }
                                }
                            }
                        }

                        // Airplane Mode Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 60
                            radius: 12
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                Text { text: "󰀝"; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: theme.peach }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { text: "Flight Isolation Mode"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text }
                                    Text { text: "Hardware soft-block all Wi-Fi and Bluetooth transmitters"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.subtext0 }
                                }

                                SciFiSwitch {
                                    checked: settingsWindow.isAirplaneMode
                                    onToggled: function(newState) {
                                        settingsWindow.isAirplaneMode = newState;
                                        Quickshell.execDetached(["rfkill", newState ? "block" : "unblock", "all"]);
                                        Quickshell.execDetached(["notify-send", "Airplane Mode", newState ? "All Radios Blocked" : "Radios Restored"]);
                                    }
                                }
                            }
                        }
                    }

                    // --------------------------------------------------------
                    // 3. SOUND
                    // --------------------------------------------------------
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 2
                        width: parent.width - 16
                        spacing: 16

                        Text {
                            text: "AUDIO STATIONS & VOLUME CONTROL"
                            font.family: "JetBrains Mono"
                            font.bold: true
                            font.pixelSize: 11
                            color: theme.subtext0
                        }

                        // Master Output Volume Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 84
                            radius: 12
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text { text: "󰕾"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18; color: theme.blue }
                                    Text { text: "Master Output Stream"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text; Layout.fillWidth: true }
                                    Rectangle {
                                        width: 50; height: 22; radius: 6
                                        color: theme.mantle
                                        Text {
                                            anchors.centerIn: parent
                                            text: Math.round((settingsWindow.sinkAudio ? settingsWindow.sinkAudio.volume : 0.75) * 100) + "%"
                                            font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; color: theme.blue
                                        }
                                    }
                                }

                                SciFiSlider {
                                    Layout.fillWidth: true
                                    from: 0.0
                                    to: 1.0
                                    value: settingsWindow.sinkAudio ? settingsWindow.sinkAudio.volume : 0.75
                                    trackColor: theme.blue
                                    onMoved: function(val) {
                                        if (settingsWindow.sinkAudio) settingsWindow.sinkAudio.volume = val;
                                    }
                                }
                            }
                        }

                        // Microphone Input Volume Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 84
                            radius: 12
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text { text: "󰍬"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18; color: theme.peach }
                                    Text { text: "Microphone Input Stream"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text; Layout.fillWidth: true }
                                    Rectangle {
                                        width: 50; height: 22; radius: 6
                                        color: theme.mantle
                                        Text {
                                            anchors.centerIn: parent
                                            text: Math.round((settingsWindow.sourceAudio ? settingsWindow.sourceAudio.volume : 0.50) * 100) + "%"
                                            font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; color: theme.peach
                                        }
                                    }
                                }

                                SciFiSlider {
                                    Layout.fillWidth: true
                                    from: 0.0
                                    to: 1.0
                                    value: settingsWindow.sourceAudio ? settingsWindow.sourceAudio.volume : 0.50
                                    trackColor: theme.peach
                                    onMoved: function(val) {
                                        if (settingsWindow.sourceAudio) settingsWindow.sourceAudio.volume = val;
                                    }
                                }
                            }
                        }
                    }

                    // --------------------------------------------------------
                    // 4. NOTIFICATIONS
                    // --------------------------------------------------------
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 3
                        width: parent.width - 16
                        spacing: 14

                        Text {
                            text: "DESKTOP NOTIFICATION CONTROLS"
                            font.family: "JetBrains Mono"
                            font.bold: true
                            font.pixelSize: 11
                            color: theme.subtext0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 64
                            radius: 12
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                Text { text: "󰂛"; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: theme.mauve }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { text: "Do Not Disturb (DND)"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text }
                                    Text { text: "Suppress all banner alerts and audio cues during focus sessions"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.subtext0 }
                                }

                                SciFiSwitch {
                                    checked: ShellBridge.dndEnabled
                                    onToggled: function(newState) {
                                        ShellBridge.setDnd(newState);
                                        Quickshell.execDetached(["notify-send", "Notifications", newState ? "Do Not Disturb Activated" : "Do Not Disturb Deactivated"]);
                                    }
                                }
                            }
                        }
                    }

                    // --------------------------------------------------------
                    // 5. BLUETOOTH
                    // --------------------------------------------------------
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 4
                        width: parent.width - 16
                        spacing: 14

                        Text {
                            text: "WIRELESS BLUETOOTH CONTROLS"
                            font.family: "JetBrains Mono"
                            font.bold: true
                            font.pixelSize: 11
                            color: theme.subtext0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 64
                            radius: 12
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                Text { text: "󰂯"; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: theme.blue }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { text: "Bluetooth Radio Power"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text }
                                    Text { text: "Toggle BlueZ bluetooth daemon controller"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.subtext0 }
                                }

                                SciFiSwitch {
                                    checked: settingsWindow.isBtPowered
                                    onToggled: function(newState) {
                                        settingsWindow.isBtPowered = newState;
                                        Quickshell.execDetached(["bluetoothctl", "power", newState ? "on" : "off"]);
                                        Quickshell.execDetached(["notify-send", "Bluetooth", newState ? "Bluetooth Enabled" : "Bluetooth Disabled"]);
                                    }
                                }
                            }
                        }
                    }

                    // --------------------------------------------------------
                    // 6. PRIVACY
                    // --------------------------------------------------------
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 5
                        width: parent.width - 16
                        spacing: 14

                        Text {
                            text: "SECURITY & SATELLITE PRIVACY"
                            font.family: "JetBrains Mono"
                            font.bold: true
                            font.pixelSize: 11
                            color: theme.subtext0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 64
                            radius: 12
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                Text { text: "󰍎"; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: theme.teal }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { text: "IP Geolocation Telemetry"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text }
                                    Text { text: "Allow local orbital weather widget to query approximate city location"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.subtext0 }
                                }

                                SciFiSwitch { checked: true }
                            }
                        }
                    }

                    // --------------------------------------------------------
                    // 7. ACCOUNTS
                    // --------------------------------------------------------
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 6
                        width: parent.width - 16
                        spacing: 14

                        Text {
                            text: "ACTIVE USER SESSION"
                            font.family: "JetBrains Mono"
                            font.bold: true
                            font.pixelSize: 11
                            color: theme.subtext0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 94
                            radius: 14
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 16

                                Rectangle {
                                    width: 58; height: 58; radius: 29
                                    color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.22)
                                    border.color: theme.accent
                                    border.width: 2

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰀉"
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 28
                                        color: theme.accent
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Text {
                                        text: Quickshell.env("USER") || "galaxy_user"
                                        font.family: "JetBrains Mono"
                                        font.bold: true
                                        font.pixelSize: 15
                                        color: theme.text
                                    }

                                    Text {
                                        text: "Compositor: Wayland (Hyprland / Quickshell)"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 10
                                        color: theme.subtext0
                                    }

                                    Text {
                                        text: "Shell Environment: /usr/bin/fish"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 9
                                        color: theme.overlay0
                                    }
                                }
                            }
                        }
                    }

                    // --------------------------------------------------------
                    // 8. SYSTEM
                    // --------------------------------------------------------
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 7
                        width: parent.width - 16
                        spacing: 14

                        Text {
                            text: "SYSTEM SPECIFICATIONS & REPOSITORY"
                            font.family: "JetBrains Mono"
                            font.bold: true
                            font.pixelSize: 11
                            color: theme.subtext0
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 105
                            radius: 14
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6

                                RowLayout {
                                    spacing: 8
                                    Text { text: "󰣇"; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; color: theme.teal }
                                    Text { text: settingsWindow.osName; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 13; color: theme.text }
                                }

                                Text {
                                    text: "Kernel: " + settingsWindow.kernelVer
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 11
                                    color: theme.subtext0
                                }

                                Text {
                                    text: "System Telemetry: " + settingsWindow.uptimeStr + "  |  Root Disk: " + settingsWindow.diskUsageStr
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
                                    color: theme.overlay0
                                }
                            }
                        }

                        Rectangle {
                            height: 38
                            width: 220
                            radius: 10
                            color: updateBtnMa.containsMouse ? Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.28) : theme.teal

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "󰚰"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: theme.crust }
                                Text { text: "Check for Updates"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: theme.crust }
                            }

                            MouseArea {
                                id: updateBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
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
    }
}
