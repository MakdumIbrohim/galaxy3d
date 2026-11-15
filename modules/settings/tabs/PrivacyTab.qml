import QtQuick
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: root
    required property var theme

    spacing: 14

    Text {
        text: "SECURITY & SATELLITE PRIVACY"
        font.family: "JetBrains Mono"
        font.bold: true
        font.pixelSize: 11
        color: root.theme.subtext0
    }

    Rectangle {
        Layout.fillWidth: true
        height: 64
        radius: 12
        color: root.theme.surface0
        border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text { text: "󰍎"; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: root.theme.teal }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "IP Geolocation Telemetry"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: root.theme.text }
                Text { text: "Allow local orbital weather widget to query approximate city location"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.subtext0 }
            }

            SciFiSwitch {
                checked: true
                activeColor: root.theme.accent
                inactiveColor: root.theme.surface1
                borderColor: root.theme.surface2
                subtextColor: root.theme.subtext0
            }
        }
    }
}
