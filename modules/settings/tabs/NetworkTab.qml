import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../components"

ColumnLayout {
    id: root
    required property var theme
    property bool isAirplaneMode: false
    signal closeSettingsRequested()

    spacing: 14

    Text {
        text: "COMMUNICATION & SATELLITE LINKS"
        font.family: "JetBrains Mono"
        font.bold: true
        font.pixelSize: 11
        color: root.theme.subtext0
    }

    // Wi-Fi Scanner Card
    Rectangle {
        Layout.fillWidth: true
        height: 60
        radius: 12
        color: root.theme.surface0
        border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text { text: "󰤨"; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: root.theme.blue }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Orbital Satellite & Wi-Fi Scanner"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: root.theme.text }
                Text { text: "Launch radar telemetry scanner and connect to wireless relays"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.subtext0 }
            }

            Rectangle {
                width: 115
                height: 32
                radius: 8
                color: scanBtnMa.containsMouse ? Qt.rgba(root.theme.blue.r, root.theme.blue.g, root.theme.blue.b, 0.3) : root.theme.blue

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "󰑐"; font.family: "Iosevka Nerd Font"; font.pixelSize: 12; color: root.theme.crust }
                    Text { text: "Open Radar"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; color: root.theme.crust }
                }

                MouseArea {
                    id: scanBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.closeSettingsRequested();
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
        color: root.theme.surface0
        border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text { text: "󰀝"; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: root.theme.peach }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Flight Isolation Mode"; font.family: "JetBrains Mono"; font.bold: true; font.pixelSize: 12; color: root.theme.text }
                Text { text: "Hardware soft-block all Wi-Fi and Bluetooth transmitters"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.subtext0 }
            }

            SciFiSwitch {
                checked: root.isAirplaneMode
                activeColor: root.theme.accent
                inactiveColor: root.theme.surface1
                borderColor: root.theme.surface2
                subtextColor: root.theme.subtext0
                onToggled: function(newState) {
                    root.isAirplaneMode = newState;
                    Quickshell.execDetached(["rfkill", newState ? "block" : "unblock", "all"]);
                    Quickshell.execDetached(["notify-send", "Airplane Mode", newState ? "All Radios Blocked" : "Radios Restored"]);
                }
            }
        }
    }
}
