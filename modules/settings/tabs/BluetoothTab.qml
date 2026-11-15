import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"

ColumnLayout {
    id: root
    required property var theme
    property bool isBtPowered: false

    spacing: 14

    Text {
        text: "WIRELESS BLUETOOTH CONTROLS"
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

            Text { text: "󰂯"; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: root.theme.blue }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Bluetooth Radio Power"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: root.theme.text }
                Text { text: "Toggle BlueZ bluetooth daemon controller"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.subtext0 }
            }

            SciFiSwitch {
                checked: root.isBtPowered
                activeColor: root.theme.accent
                inactiveColor: root.theme.surface1
                borderColor: root.theme.surface2
                subtextColor: root.theme.subtext0
                onToggled: function(newState) {
                    root.isBtPowered = newState;
                    Quickshell.execDetached(["bluetoothctl", "power", newState ? "on" : "off"]);
                    Quickshell.execDetached(["notify-send", "Bluetooth", newState ? "Bluetooth Enabled" : "Bluetooth Disabled"]);
                }
            }
        }
    }
}
