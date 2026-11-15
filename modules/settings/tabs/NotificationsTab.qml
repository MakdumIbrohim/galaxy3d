import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../components"

ColumnLayout {
    id: root
    required property var theme

    spacing: 14

    Text {
        text: "DESKTOP NOTIFICATION CONTROLS"
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

            Text { text: "󰂛"; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: root.theme.mauve }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Do Not Disturb (DND)"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: root.theme.text }
                Text { text: "Suppress all banner alerts and audio cues during focus sessions"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.subtext0 }
            }

            SciFiSwitch {
                checked: ShellBridge.dndEnabled
                activeColor: root.theme.accent
                inactiveColor: root.theme.surface1
                borderColor: root.theme.surface2
                subtextColor: root.theme.subtext0
                onToggled: function(newState) {
                    ShellBridge.setDnd(newState);
                    Quickshell.execDetached(["notify-send", "Notifications", newState ? "Do Not Disturb Activated" : "Do Not Disturb Deactivated"]);
                }
            }
        }
    }
}
