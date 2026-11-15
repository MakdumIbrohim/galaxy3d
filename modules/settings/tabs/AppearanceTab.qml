import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../services"

ColumnLayout {
    id: root
    required property var theme
    required property var paths

    spacing: 16

    // Wallpaper Header
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "DESKTOP WALLPAPER"
            font.family: "JetBrains Mono"
            font.bold: true
            font.pixelSize: 11
            color: root.theme.subtext0
            Layout.fillWidth: true
        }
        Text {
            text: ShellBridge.currentWallpaper !== ""
                ? ShellBridge.currentWallpaper.substring(ShellBridge.currentWallpaper.lastIndexOf("/") + 1)
                : "Default"
            font.family: "JetBrains Mono"
            font.pixelSize: 9
            color: root.theme.overlay0
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
                color: root.theme.surface0
                border.color: isSelected
                    ? root.theme.accent
                    : (selectWpMa.containsMouse ? root.theme.surface2 : Qt.rgba(1, 1, 1, 0.08))
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
                            color: isSelected ? root.theme.accent : "#ffffff"
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
                    color: root.theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "󰄬"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 12
                        color: root.theme.crust
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
            color: randWpMa.containsMouse ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.25) : root.theme.surface0
            border.color: randWpMa.containsMouse ? root.theme.accent : Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { text: "󰒝"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: root.theme.accent }
                Text { text: "Randomize"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; color: root.theme.text }
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
            color: customWpMa.containsMouse ? Qt.rgba(root.theme.teal.r, root.theme.teal.g, root.theme.teal.b, 0.25) : root.theme.surface0
            border.color: customWpMa.containsMouse ? root.theme.teal : Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { text: "󰋩"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: root.theme.teal }
                Text { text: "Browse Image..."; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; color: root.theme.text }
            }

            MouseArea {
                id: customWpMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["bash", "-c", "FILE=$(zenity --file-selection --title='Select Wallpaper' --file-filter='Images | *.jpg *.png *.jpeg *.webp' 2>/dev/null) ; if [ -n \"$FILE\" ]; then echo \"$FILE\" > " + root.paths.configDir + "/wallpaper.conf ; notify-send 'Wallpaper Updated' \"$FILE\"; fi"]);
                }
            }
        }
    }

    Rectangle {
        height: 1
        Layout.fillWidth: true
        color: Qt.rgba(root.theme.surface1.r, root.theme.surface1.g, root.theme.surface1.b, 0.3)
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
            color: root.theme.surface0
            border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.3)
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
                    color: root.theme.subtext0
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: root.theme.mantle

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: ShellBridge.isDarkMode ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.22) : "transparent"
                            border.color: ShellBridge.isDarkMode ? root.theme.accent : "transparent"
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "󰽥"; font.family: "Iosevka Nerd Font"; font.pixelSize: 12; color: ShellBridge.isDarkMode ? root.theme.accent : root.theme.subtext0 }
                                Text { text: "Dark Mode"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: ShellBridge.isDarkMode; color: ShellBridge.isDarkMode ? root.theme.text : root.theme.subtext0 }
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

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: !ShellBridge.isDarkMode ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.22) : "transparent"
                            border.color: !ShellBridge.isDarkMode ? root.theme.accent : "transparent"
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "󰖙"; font.family: "Iosevka Nerd Font"; font.pixelSize: 12; color: !ShellBridge.isDarkMode ? root.theme.accent : root.theme.subtext0 }
                                Text { text: "Light Mode"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: !ShellBridge.isDarkMode; color: !ShellBridge.isDarkMode ? root.theme.text : root.theme.subtext0 }
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
            color: root.theme.surface0
            border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.3)
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
                        color: root.theme.subtext0
                        Layout.fillWidth: true
                    }
                    Text {
                        text: ShellBridge.activeAccent
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        font.bold: true
                        color: root.theme.accent
                    }
                }

                RowLayout {
                    spacing: 10

                    Repeater {
                        model: [
                            { "name": "Mauve",    "col": root.theme.mauve },
                            { "name": "Blue",     "col": root.theme.blue },
                            { "name": "Sapphire", "col": root.theme.sapphire },
                            { "name": "Teal",     "col": root.theme.teal },
                            { "name": "Peach",    "col": root.theme.peach },
                            { "name": "Green",    "col": root.theme.green },
                            { "name": "Pink",     "col": root.theme.pink }
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
        color: Qt.rgba(root.theme.surface1.r, root.theme.surface1.g, root.theme.surface1.b, 0.3)
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
            color: root.theme.subtext0
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
                        ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.16)
                        : (hudMa.containsMouse ? Qt.rgba(root.theme.surface1.r, root.theme.surface1.g, root.theme.surface1.b, 0.4) : root.theme.surface0)
                    border.color: isSelected
                        ? root.theme.accent
                        : (hudMa.containsMouse ? root.theme.surface2 : Qt.rgba(1, 1, 1, 0.08))
                    border.width: isSelected ? 1.5 : 1

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            width: 36; height: 36; radius: 8
                            color: isSelected ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.25) : root.theme.surface1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 16
                                color: isSelected ? root.theme.accent : root.theme.subtext0
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
                                color: isSelected ? root.theme.text : root.theme.subtext0
                            }
                            Text {
                                text: modelData.desc
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8
                                color: root.theme.overlay0
                            }
                        }

                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: isSelected ? root.theme.accent : "transparent"
                            border.color: isSelected ? root.theme.accent : root.theme.surface2
                            border.width: 1.5

                            Text {
                                visible: isSelected
                                anchors.centerIn: parent
                                text: "󰄬"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 10
                                color: root.theme.crust
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
