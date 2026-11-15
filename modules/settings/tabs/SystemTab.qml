import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    required property var theme
    property string osName: "CachyOS Linux (x86_64)"
    property string kernelVer: "Linux 6.x"
    property string uptimeStr: "Up 2 hours"
    property string diskUsageStr: "34GB / 256GB"

    signal updateCheckRequested()

    spacing: 14

    Text {
        text: "SYSTEM SPECIFICATIONS & REPOSITORY"
        font.family: "JetBrains Mono"
        font.bold: true
        font.pixelSize: 11
        color: root.theme.subtext0
    }

    Rectangle {
        Layout.fillWidth: true
        height: 105
        radius: 14
        color: root.theme.surface0
        border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                spacing: 8
                Text { text: "󰣇"; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; color: root.theme.teal }
                Text { text: root.osName; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 13; color: root.theme.text }
            }

            Text {
                text: "Kernel: " + root.kernelVer
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                color: root.theme.subtext0
            }

            Text {
                text: "System Telemetry: " + root.uptimeStr + "  |  Root Disk: " + root.diskUsageStr
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                color: root.theme.overlay0
            }
        }
    }

    Rectangle {
        height: 38
        width: 220
        radius: 10
        color: updateBtnMa.containsMouse ? Qt.rgba(root.theme.teal.r, root.theme.teal.g, root.theme.teal.b, 0.28) : root.theme.teal

        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text { text: "󰚰"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: root.theme.crust }
            Text { text: "Check for Updates"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: root.theme.crust }
        }

        MouseArea {
            id: updateBtnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.updateCheckRequested()
        }
    }
}
