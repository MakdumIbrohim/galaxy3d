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
        { "name": "Appearance",     "icon": "󰔎", "desc": "Wallpaper, theme, accent colors, and fonts" },
        { "name": "Network",        "icon": "󰤨", "desc": "Wi-Fi, satellites, DNS, and proxy" },
        { "name": "Sound",          "icon": "󰕾", "desc": "Output/input volume and audio devices" },
        { "name": "Notifications",  "icon": "󰂚", "desc": "App permissions and Do Not Disturb (DND)" },
        { "name": "Bluetooth",      "icon": "󰂯", "desc": "Wireless device connectivity" },
        { "name": "Privacy",        "icon": "󰒃", "desc": "Data security and screen lock" },
        { "name": "Accounts",       "icon": "󰀉", "desc": "User profile, avatar, and shell session" },
        { "name": "System",         "icon": "󰋽", "desc": "Device information and system updates" }
    ]

    // Wallpaper and audio tracking
    property string currentWallpaper: ""
    property bool isDarkMode: ShellBridge.isDarkMode
    property string activeAccent: ShellBridge.activeAccent
    property real fontScale: 1.0
    property bool isBtPowered: false
    property bool isAirplaneMode: false

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

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].filter(n => n)
    }
    readonly property var sinkAudio: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio : null
    readonly property var sourceAudio: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) ? Pipewire.defaultAudioSource.audio : null

    // System info properties
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

    // Backdrop dismissal
    MouseArea {
        anchors.fill: parent
        onClicked: settingsWindow.visible = false
    }

    // Settings Window Card
    Rectangle {
        id: settingsCard
        width: Math.min(940, parent.width - 60)
        height: Math.min(680, parent.height - 60)
        anchors.centerIn: parent
        radius: 18
        color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.96)
        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
        border.width: 1.5

        MouseArea {
            anchors.fill: parent
            onClicked: {}
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
                color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.6)
                radius: 18

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Sidebar Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 18; color: theme.mauve }
                        Text { text: "SETTINGS"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 13; color: theme.text }
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.5) }

                    // Category List
                    ListView {
                        id: catListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: settingsWindow.categories
                        spacing: 4
                        clip: true

                        delegate: Rectangle {
                            width: catListView.width
                            height: 44
                            radius: 10
                            color: settingsWindow.activeCategoryIndex === index
                                ? Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.2)
                                : (catMa.containsMouse ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.4) : "transparent")
                            border.color: settingsWindow.activeCategoryIndex === index ? theme.mauve : "transparent"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12; anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 16
                                    color: settingsWindow.activeCategoryIndex === index ? theme.mauve : theme.subtext0
                                }
                                Text {
                                    text: modelData.name
                                    font.family: "JetBrains Mono"
                                    font.weight: settingsWindow.activeCategoryIndex === index ? Font.Bold : Font.Normal
                                    font.pixelSize: 12
                                    color: settingsWindow.activeCategoryIndex === index ? theme.text : theme.subtext0
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

                    // Bottom close button
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 8
                        color: sidebarCloseMa.containsMouse ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.2) : theme.surface0
                        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.3)
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "󰅖"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: theme.red }
                            Text { text: "Close Settings"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: theme.text }
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

            Rectangle { width: 1; Layout.fillHeight: true; color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.4) }

            // ========================================================
            // RIGHT CONTENT PANE
            // ========================================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                anchors.margins: 20
                spacing: 16

                // Breadcrumb & Category Title
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: settingsWindow.categories[settingsWindow.activeCategoryIndex].icon
                        font.family: "Iosevka Nerd Font"; font.pixelSize: 22; color: theme.blue
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: settingsWindow.categories[settingsWindow.activeCategoryIndex].name
                            font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 16; color: theme.text
                        }
                        Text {
                            text: settingsWindow.categories[settingsWindow.activeCategoryIndex].desc
                            font.family: "JetBrains Mono"; font.pixelSize: 10; color: theme.subtext0
                        }
                    }
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.4) }

                // Dynamic Category Panes
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // --- 1. APPEARANCE ---
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 0
                        width: parent.width - 20
                        spacing: 14

                        Text { text: "Desktop Wallpaper"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }

                        RowLayout {
                            spacing: 12
                            Repeater {
                                model: [
                                    { "name": "Cosmic Galaxy", "file": "/usr/share/wallpapers/cachyos-wallpapers/cachygalaxy99.jpg" },
                                    { "name": "Lunar Horizon", "file": "/usr/share/wallpapers/cachyos-wallpapers/CachyOS_Moon.jpg" },
                                    { "name": "Emerald Space", "file": "/usr/share/wallpapers/cachyos-wallpapers/CachyOS_GreenSpace.png" }
                                ]
                                delegate: Rectangle {
                                    width: 140; height: 85; radius: 8
                                    color: theme.surface0
                                    border.color: selectWpMa.containsMouse ? theme.mauve : theme.surface2
                                    border.width: 1.5
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: "file://" + modelData.file
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                    Rectangle {
                                        anchors.bottom: parent.bottom; width: parent.width; height: 22
                                        color: Qt.rgba(0, 0, 0, 0.7)
                                        Text {
                                            anchors.centerIn: parent; text: modelData.name
                                            font.family: "JetBrains Mono"; font.pixelSize: 9; color: "#fff"
                                        }
                                    }
                                    MouseArea {
                                        id: selectWpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            ShellBridge.setWallpaper(modelData.file);
                                            Quickshell.execDetached(["notify-send", "Wallpaper Updated", modelData.name]);
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                spacing: 8
                                Button {
                                    text: "Random"
                                    contentItem: Text { text: parent.text; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: theme.crust }
                                    background: Rectangle { radius: 8; color: theme.mauve }
                                    onClicked: ShellBridge.randomWallpaper()
                                }
                                Button {
                                    text: "Custom..."
                                    contentItem: Text { text: parent.text; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: theme.crust }
                                    background: Rectangle { radius: 8; color: theme.teal }
                                    onClicked: {
                                        Quickshell.execDetached(["bash", "-c", "FILE=$(zenity --file-selection --title='Select Wallpaper' --file-filter='Images | *.jpg *.png *.jpeg *.webp' 2>/dev/null) ; if [ -n \"$FILE\" ]; then echo \"$FILE\" > " + paths.configDir + "/wallpaper.conf ; notify-send 'Wallpaper Updated' \"$FILE\"; fi"]);
                                    }
                                }
                            }
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.3) }

                        // Theme Mode & Accent
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            ColumnLayout {
                                Text { text: "Base Theme"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }
                                RowLayout {
                                    spacing: 8
                                    Button {
                                        text: "Dark"
                                        background: Rectangle {
                                            radius: 8
                                            color: ShellBridge.isDarkMode ? theme.surface1 : theme.base
                                            border.color: ShellBridge.isDarkMode ? theme.mauve : theme.surface2
                                            border.width: ShellBridge.isDarkMode ? 2 : 1
                                        }
                                        contentItem: Text {
                                            text: parent.text
                                            font.family: "JetBrains Mono"
                                            font.weight: ShellBridge.isDarkMode ? Font.Bold : Font.Normal
                                            font.pixelSize: 11
                                            color: ShellBridge.isDarkMode ? theme.mauve : theme.subtext0
                                        }
                                        onClicked: {
                                            ShellBridge.setDarkMode(true);
                                            Quickshell.execDetached(["notify-send", "Theme Mode", "Switched to Dark Theme"]);
                                        }
                                    }
                                    Button {
                                        text: "Light"
                                        background: Rectangle {
                                            radius: 8
                                            color: !ShellBridge.isDarkMode ? theme.surface1 : theme.surface0
                                            border.color: !ShellBridge.isDarkMode ? theme.mauve : theme.surface2
                                            border.width: !ShellBridge.isDarkMode ? 2 : 1
                                        }
                                        contentItem: Text {
                                            text: parent.text
                                            font.family: "JetBrains Mono"
                                            font.weight: !ShellBridge.isDarkMode ? Font.Bold : Font.Normal
                                            font.pixelSize: 11
                                            color: !ShellBridge.isDarkMode ? theme.mauve : theme.subtext0
                                        }
                                        onClicked: {
                                            ShellBridge.setDarkMode(false);
                                            Quickshell.execDetached(["notify-send", "Theme Mode", "Switched to Light Theme"]);
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Text { text: "Accent Color"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }
                                RowLayout {
                                    spacing: 8
                                    Repeater {
                                        model: [
                                            { "name": "Mauve", "col": theme.mauve },
                                            { "name": "Blue",  "col": theme.blue },
                                            { "name": "Teal",  "col": theme.teal },
                                            { "name": "Peach", "col": theme.peach },
                                            { "name": "Green", "col": theme.green }
                                        ]
                                        delegate: Rectangle {
                                            readonly property bool isSelected: ShellBridge.activeAccent.toLowerCase() === modelData.name.toLowerCase()
                                            width: 26; height: 26; radius: 13; color: modelData.col
                                            border.color: "#ffffff"
                                            border.width: isSelected ? 2.5 : (swatchMa.containsMouse ? 1.5 : 0)
                                            scale: isSelected ? 1.15 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 150 } }

                                            MouseArea {
                                                id: swatchMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    ShellBridge.setAccent(modelData.name);
                                                    Quickshell.execDetached(["notify-send", "Accent Color", "System accent changed to " + modelData.name]);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.3) }

                        // TopBar Layout Style
                        ColumnLayout {
                            spacing: 8
                            Text { text: "TopBar Style"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }

                            RowLayout {
                                spacing: 10

                                Repeater {
                                    model: [
                                        { id: "cyber",    name: "Cyber Dock",   desc: "3 Floating Glass Islands", icon: "󰕰" },
                                        { id: "tactical", name: "Tactical HUD", desc: "Full-Width Sci-Fi Rail",   icon: "󰄛" },
                                        { id: "capsule",  name: "Capsule",      desc: "Compact Minimalist Pills", icon: "󰝥" }
                                    ]

                                    delegate: Rectangle {
                                        readonly property bool isSelected: ShellBridge.topbarStyle === modelData.id
                                        width: 155; height: 54; radius: 10
                                        color: isSelected ? Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.16) : theme.surface0
                                        border.color: isSelected ? theme.mauve : (styleMa.containsMouse ? theme.surface2 : Qt.rgba(1, 1, 1, 0.08))
                                        border.width: isSelected ? 1.5 : 1

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 8

                                            Text {
                                                text: modelData.icon
                                                font.family: "Iosevka Nerd Font"
                                                font.pixelSize: 16
                                                color: isSelected ? theme.mauve : theme.subtext0
                                            }

                                            ColumnLayout {
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
                                        }

                                        MouseArea {
                                            id: styleMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                ShellBridge.setTopbarStyle(modelData.id);
                                                Quickshell.execDetached(["notify-send", "TopBar Style", "Switched to " + modelData.name]);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // --- 2. NETWORK ---
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 1
                        width: parent.width - 20
                        spacing: 12

                        Text { text: "Wireless & Satellite Connections"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }

                        Rectangle {
                            Layout.fillWidth: true; height: 48; radius: 10; color: theme.surface0
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12
                                Text { text: "Open Satellite / Wi-Fi Scanner Panel"; font.family: "JetBrains Mono"; font.pixelSize: 12; color: theme.text; Layout.fillWidth: true }
                                Button {
                                    text: "Open Scanner"
                                    background: Rectangle { radius: 6; color: theme.blue }
                                    contentItem: Text { text: parent.text; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: theme.crust }
                                    onClicked: {
                                        settingsWindow.visible = false;
                                        ShellBridge.openNetwork();
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 48; radius: 10; color: theme.surface0
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12
                                Text { text: "Airplane Mode"; font.family: "JetBrains Mono"; font.pixelSize: 12; color: theme.text; Layout.fillWidth: true }
                                Switch {
                                    checked: settingsWindow.isAirplaneMode
                                    onToggled: {
                                        settingsWindow.isAirplaneMode = checked;
                                        Quickshell.execDetached(["rfkill", checked ? "block" : "unblock", "all"]);
                                        Quickshell.execDetached(["notify-send", "Airplane Mode", checked ? "All Radios Blocked" : "Radios Restored"]);
                                    }
                                }
                            }
                        }
                    }

                    // --- 3. SOUND ---
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 2
                        width: parent.width - 20
                        spacing: 14

                        Text { text: "Output Volume (Master)"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 10
                            Text { text: "󰕾"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18; color: theme.blue }
                            Slider {
                                Layout.fillWidth: true
                                from: 0.0; to: 1.0
                                value: settingsWindow.sinkAudio ? settingsWindow.sinkAudio.volume : 0.75
                                onMoved: if (settingsWindow.sinkAudio) settingsWindow.sinkAudio.volume = value
                            }
                            Text {
                                text: Math.round((settingsWindow.sinkAudio ? settingsWindow.sinkAudio.volume : 0.75) * 100) + "%"
                                font.family: "JetBrains Mono"; font.pixelSize: 12; color: theme.text; width: 45
                            }
                        }

                        Text { text: "Input Volume (Microphone)"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 10
                            Text { text: "󰍬"; font.family: "Iosevka Nerd Font"; font.pixelSize: 18; color: theme.peach }
                            Slider {
                                Layout.fillWidth: true
                                from: 0.0; to: 1.0
                                value: settingsWindow.sourceAudio ? settingsWindow.sourceAudio.volume : 0.50
                                onMoved: if (settingsWindow.sourceAudio) settingsWindow.sourceAudio.volume = value
                            }
                            Text {
                                text: Math.round((settingsWindow.sourceAudio ? settingsWindow.sourceAudio.volume : 0.50) * 100) + "%"
                                font.family: "JetBrains Mono"; font.pixelSize: 12; color: theme.text; width: 45
                            }
                        }
                    }

                    // --- 4. NOTIFICATIONS ---
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 3
                        width: parent.width - 20
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true; height: 50; radius: 10; color: theme.surface0
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: "Do Not Disturb (DND)"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text }
                                    Text { text: "Mute all desktop notification popups"; font.family: "JetBrains Mono"; font.pixelSize: 10; color: theme.subtext0 }
                                }
                                Switch {
                                    checked: ShellBridge.dndEnabled
                                    onToggled: {
                                        ShellBridge.setDnd(checked);
                                        Quickshell.execDetached(["notify-send", "Notifications", checked ? "Do Not Disturb Activated" : "Do Not Disturb Deactivated"]);
                                    }
                                }
                            }
                        }
                    }

                    // --- 5. BLUETOOTH ---
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 4
                        width: parent.width - 20
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true; height: 50; radius: 10; color: theme.surface0
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12
                                Text { text: "Bluetooth Power"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text; Layout.fillWidth: true }
                                Switch {
                                    checked: settingsWindow.isBtPowered
                                    onToggled: {
                                        settingsWindow.isBtPowered = checked;
                                        Quickshell.execDetached(["bluetoothctl", "power", checked ? "on" : "off"]);
                                        Quickshell.execDetached(["notify-send", "Bluetooth", checked ? "Bluetooth Enabled" : "Bluetooth Disabled"]);
                                    }
                                }
                            }
                        }
                    }

                    // --- 6. PRIVACY ---
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 5
                        width: parent.width - 20
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true; height: 50; radius: 10; color: theme.surface0
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: "Automatic Location Services"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text }
                                    Text { text: "Use IP geolocation for weather widget"; font.family: "JetBrains Mono"; font.pixelSize: 10; color: theme.subtext0 }
                                }
                                Switch { checked: true }
                            }
                        }
                    }

                    // --- 7. ACCOUNTS ---
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 6
                        width: parent.width - 20
                        spacing: 14

                        RowLayout {
                            spacing: 14
                            Rectangle {
                                width: 56; height: 56; radius: 28; color: theme.mauve
                                Text { anchors.centerIn: parent; text: "󰀉"; font.family: "Iosevka Nerd Font"; font.pixelSize: 26; color: theme.crust }
                            }
                            ColumnLayout {
                                Text { text: Quickshell.env("USER"); font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 14; color: theme.text }
                                Text { text: "Default Shell: /usr/bin/fish"; font.family: "JetBrains Mono"; font.pixelSize: 11; color: theme.subtext0 }
                            }
                        }
                    }

                    // --- 8. SYSTEM & ABOUT ---
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 7
                        width: parent.width - 20
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true; height: 90; radius: 10; color: theme.surface0
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 4
                                Text { text: settingsWindow.osName; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 13; color: theme.teal }
                                Text { text: "Kernel: " + settingsWindow.kernelVer; font.family: "JetBrains Mono"; font.pixelSize: 11; color: theme.subtext0 }
                                Text { text: "Status: " + settingsWindow.uptimeStr + "  |  Storage: " + settingsWindow.diskUsageStr; font.family: "JetBrains Mono"; font.pixelSize: 10; color: theme.overlay0 }
                            }
                        }

                        Button {
                            text: "Check for System Updates"
                            contentItem: Text { text: parent.text; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: theme.crust }
                            background: Rectangle { radius: 8; color: theme.teal }
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
