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
        { "name": "Tampilan",        "icon": "󰔎", "desc": "Wallpaper, tema, warna aksen, dan font" },
        { "name": "Jaringan",        "icon": "󰤨", "desc": "Wi-Fi, satelit, DNS, dan proxy" },
        { "name": "Suara",           "icon": "󰕾", "desc": "Volume output/input dan perangkat audio" },
        { "name": "Notifikasi",      "icon": "󰂚", "desc": "Izin aplikasi dan Jangan Ganggu (DND)" },
        { "name": "Bluetooth",       "icon": "󰂯", "desc": "Koneksi perangkat nirkabel" },
        { "name": "Privasi",         "icon": "󰒃", "desc": "Keamanan data dan kunci layar" },
        { "name": "Akun",            "icon": "󰀉", "desc": "Pengguna, avatar, dan sesi shell" },
        { "name": "Sistem",          "icon": "󰋽", "desc": "Informasi perangkat dan pembaruan" }
    ]

    // Wallpaper and audio tracking
    property string currentWallpaper: ""
    property bool isDarkMode: true
    property string activeAccent: "Mauve"
    property real fontScale: 1.0

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].filter(n => n)
    }
    readonly property var sinkAudio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var sourceAudio: Pipewire.defaultAudioSource?.audio ?? null

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
                        Text { text: "PENGATURAN"; font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 13; color: theme.text }
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
                            Text { text: "Tutup Pengaturan"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: theme.text }
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

                    // --- 1. TAMPILAN ---
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 0
                        width: parent.width - 20
                        spacing: 14

                        Text { text: "Wallpaper Desktop"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }

                        RowLayout {
                            spacing: 12
                            Repeater {
                                model: [
                                    { "name": "Deep Sky", "file": "wallhaven-1pkq63.jpg" },
                                    { "name": "Starry Night", "file": "wallhaven-8378y1.jpg" },
                                    { "name": "CachyOS", "file": "default-wallpaper.png" }
                                ]
                                delegate: Rectangle {
                                    width: 140; height: 85; radius: 8
                                    color: theme.surface0
                                    border.color: selectWpMa.containsMouse ? theme.mauve : theme.surface2
                                    border.width: 1.5
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: "file://" + paths.home + "/Pictures/Wallpapers/" + modelData.file
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                    Rectangle {
                                        anchors.bottom: parent.bottom; width: parent.width; height: 22
                                        color: Qt.rgba(0, 0, 0, 0.65)
                                        Text {
                                            anchors.centerIn: parent; text: modelData.name
                                            font.family: "JetBrains Mono"; font.pixelSize: 9; color: "#fff"
                                        }
                                    }
                                    MouseArea {
                                        id: selectWpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let fullPath = paths.home + "/Pictures/Wallpapers/" + modelData.file;
                                            Quickshell.execDetached(["bash", "-c", "echo '" + fullPath + "' > " + paths.configDir + "/wallpaper.conf"]);
                                            Quickshell.execDetached(["notify-send", "Wallpaper Diperbarui", modelData.name]);
                                        }
                                    }
                                }
                            }

                            Button {
                                text: "Acak"
                                contentItem: Text { text: parent.text; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: theme.crust }
                                background: Rectangle { radius: 8; color: theme.mauve }
                                onClicked: Quickshell.execDetached(["qs", "-c", "galaxy3d", "ipc", "call", "wallpaper", "random"])
                            }
                        }

                        Rectangle { height: 1; Layout.fillWidth: true; color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.3) }

                        // Theme Mode & Accent
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            ColumnLayout {
                                Text { text: "Tema Dasar"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }
                                RowLayout {
                                    spacing: 8
                                    Button {
                                        text: "Gelap (Dark)"
                                        background: Rectangle { radius: 8; color: theme.base; border.color: theme.mauve; border.width: 1.5 }
                                        contentItem: Text { text: parent.text; font.family: "JetBrains Mono"; font.pixelSize: 11; color: theme.text }
                                    }
                                    Button {
                                        text: "Terang (Light)"
                                        background: Rectangle { radius: 8; color: theme.surface0; border.color: theme.surface2; border.width: 1 }
                                        contentItem: Text { text: parent.text; font.family: "JetBrains Mono"; font.pixelSize: 11; color: theme.subtext0 }
                                    }
                                }
                            }

                            ColumnLayout {
                                Text { text: "Warna Aksen"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }
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
                                            width: 24; height: 24; radius: 12; color: modelData.col
                                            border.color: "#ffffff"; border.width: swatchMa.containsMouse || settingsWindow.activeAccent === modelData.name ? 2 : 0
                                            MouseArea {
                                                id: swatchMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    settingsWindow.activeAccent = modelData.name;
                                                    Quickshell.execDetached(["bash", "-c", "echo '" + modelData.name + "' > " + paths.configDir + "/accent.conf"]);
                                                    Quickshell.execDetached(["notify-send", "Warna Aksen", "Aksen sistem diganti ke " + modelData.name]);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // --- 2. JARINGAN ---
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 1
                        width: parent.width - 20
                        spacing: 12

                        Text { text: "Koneksi Nirkabel & Satelit"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }

                        Rectangle {
                            Layout.fillWidth: true; height: 48; radius: 10; color: theme.surface0
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12
                                Text { text: "Buka Panel Pemindaian Satelit / Wi-Fi"; font.family: "JetBrains Mono"; font.pixelSize: 12; color: theme.text; Layout.fillWidth: true }
                                Button {
                                    text: "Buka Scanner"
                                    background: Rectangle { radius: 6; color: theme.blue }
                                    contentItem: Text { text: parent.text; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: theme.crust }
                                    onClicked: {
                                        settingsWindow.visible = false;
                                        Quickshell.execDetached(["qs", "-c", "galaxy3d", "ipc", "call", "network", "open"]);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 48; radius: 10; color: theme.surface0
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12
                                Text { text: "Mode Pesawat (Airplane Mode)"; font.family: "JetBrains Mono"; font.pixelSize: 12; color: theme.text; Layout.fillWidth: true }
                                Switch {
                                    checked: false
                                    onToggled: Quickshell.execDetached(["rfkill", checked ? "block" : "unblock", "all"])
                                }
                            }
                        }
                    }

                    // --- 3. SUARA ---
                    ColumnLayout {
                        visible: settingsWindow.activeCategoryIndex === 2
                        width: parent.width - 20
                        spacing: 14

                        Text { text: "Volume Output (Master)"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }
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

                        Text { text: "Volume Input (Mikrofon)"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.subtext0 }
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

                    // --- 4. NOTIFIKASI ---
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
                                    Text { text: "Jangan Ganggu (Do Not Disturb)"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text }
                                    Text { text: "Senyapkan seluruh popup notifikasi desktop"; font.family: "JetBrains Mono"; font.pixelSize: 10; color: theme.subtext0 }
                                }
                                Switch { checked: false }
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
                                Text { text: "Daya Bluetooth"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text; Layout.fillWidth: true }
                                Switch {
                                    checked: false
                                    onToggled: Quickshell.execDetached(["bluetoothctl", "power", checked ? "on" : "off"])
                                }
                            }
                        }
                    }

                    // --- 6. PRIVASI ---
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
                                    Text { text: "Layanan Lokasi Otomatis"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: theme.text }
                                    Text { text: "Gunakan geolokasi IP untuk widget cuaca"; font.family: "JetBrains Mono"; font.pixelSize: 10; color: theme.subtext0 }
                                }
                                Switch { checked: true }
                            }
                        }
                    }

                    // --- 7. AKUN ---
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
                                Text { text: Quickshell.env("USER") || "makdumibrohim"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 14; color: theme.text }
                                Text { text: "Default Shell: /usr/bin/fish"; font.family: "JetBrains Mono"; font.pixelSize: 11; color: theme.subtext0 }
                            }
                        }
                    }

                    // --- 8. SISTEM & TENTANG ---
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
                            text: "Periksa Pembaruan Sistem"
                            contentItem: Text { text: parent.text; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: theme.crust }
                            background: Rectangle { radius: 8; color: theme.teal }
                            onClicked: Quickshell.execDetached(["notify-send", "Pembaruan", "Sistem Anda sudah mutakhir."])
                        }
                    }
                }
            }
        }
    }
}
