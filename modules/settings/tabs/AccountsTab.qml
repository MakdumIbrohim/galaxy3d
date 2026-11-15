import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    required property var theme

    spacing: 14

    Text {
        text: "ACTIVE USER SESSION"
        font.family: "JetBrains Mono"
        font.bold: true
        font.pixelSize: 11
        color: root.theme.subtext0
    }

    Rectangle {
        Layout.fillWidth: true
        height: 94
        radius: 14
        color: root.theme.surface0
        border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Rectangle {
                width: 58; height: 58; radius: 29
                color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.22)
                border.color: root.theme.accent
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "󰀉"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 28
                    color: root.theme.accent
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
                    color: root.theme.text
                }

                Text {
                    text: "Compositor: Wayland (Hyprland / Quickshell)"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    color: root.theme.subtext0
                }

                Text {
                    text: "Shell Environment: /usr/bin/fish"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    color: root.theme.overlay0
                }
            }
        }
    }
}
