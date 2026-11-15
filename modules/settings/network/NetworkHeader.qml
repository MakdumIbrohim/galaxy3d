import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    required property var theme
    property string activeMode: "wifi"
    property bool isScanning: false

    signal modeChanged(string newMode)
    signal scanRequested()
    signal closeRequested()

    color: Qt.rgba(root.theme.crust.r, root.theme.crust.g, root.theme.crust.b, 0.75)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 16

        // Brand & Radar Header
        RowLayout {
            spacing: 12
            Rectangle {
                width: 38; height: 38; radius: 10
                color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.2)
                border.color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.45)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰤨"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 20
                    color: root.theme.accent
                }
            }

            ColumnLayout {
                spacing: 1
                RowLayout {
                    spacing: 6
                    Text {
                        text: "SATELLITE RADAR"
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 13
                        color: root.theme.text
                    }
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: "#a6e3a1"
                    }
                }
                Text {
                    text: "FREQUENCY & TELEMETRY INTERCEPTION"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    color: root.theme.overlay0
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Mode Switcher (Capsule Segmented Control)
        Rectangle {
            width: 330
            height: 36
            radius: 10
            color: root.theme.surface0
            border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                spacing: 2

                // 1. Wi-Fi Radar Option
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: root.activeMode === "wifi" ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.22) : "transparent"
                    border.color: root.activeMode === "wifi" ? root.theme.accent : "transparent"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰤨"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: root.activeMode === "wifi" ? root.theme.accent : root.theme.subtext0 }
                        Text { text: "Wi-Fi"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: root.activeMode === "wifi"; color: root.activeMode === "wifi" ? root.theme.text : root.theme.subtext0 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modeChanged("wifi")
                    }
                }

                // 2. Bluetooth Option
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: root.activeMode === "bt" ? Qt.rgba(root.theme.blue.r, root.theme.blue.g, root.theme.blue.b, 0.22) : "transparent"
                    border.color: root.activeMode === "bt" ? root.theme.blue : "transparent"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰂯"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: root.activeMode === "bt" ? root.theme.blue : root.theme.subtext0 }
                        Text { text: "Bluetooth"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: root.activeMode === "bt"; color: root.activeMode === "bt" ? root.theme.text : root.theme.subtext0 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modeChanged("bt")
                    }
                }

                // 3. Ethernet Option
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: root.activeMode === "eth" ? Qt.rgba(root.theme.teal.r, root.theme.teal.g, root.theme.teal.b, 0.22) : "transparent"
                    border.color: root.activeMode === "eth" ? root.theme.teal : "transparent"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰈀"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: root.activeMode === "eth" ? root.theme.teal : root.theme.subtext0 }
                        Text { text: "Ethernet"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: root.activeMode === "eth"; color: root.activeMode === "eth" ? root.theme.text : root.theme.subtext0 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modeChanged("eth")
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Rescan Ping Button
        Rectangle {
            width: 110
            height: 36
            radius: 10
            color: rescanMa.containsMouse ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.25) : root.theme.surface0
            border.color: rescanMa.containsMouse ? root.theme.accent : Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: "󰑐"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 14
                    color: root.isScanning ? root.theme.accent : root.theme.subtext0
                    rotation: root.isScanning ? pingAnim.angle : 0

                    NumberAnimation on rotation {
                        id: pingAnim
                        property real angle: 0
                        running: root.isScanning
                        loops: Animation.Infinite
                        from: 0; to: 360; duration: 900
                    }
                }
                Text {
                    text: root.isScanning ? "Pinging..." : "Sweep Scan"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    font.bold: true
                    color: root.theme.text
                }
            }

            MouseArea {
                id: rescanMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.scanRequested()
            }
        }

        // Close Radar Button
        Rectangle {
            width: 36
            height: 36
            radius: 10
            color: closeRadarMa.containsMouse ? Qt.rgba(root.theme.red.r, root.theme.red.g, root.theme.red.b, 0.25) : root.theme.surface0
            border.color: closeRadarMa.containsMouse ? root.theme.red : Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰅖"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 14
                color: closeRadarMa.containsMouse ? root.theme.red : root.theme.subtext0
            }

            MouseArea {
                id: closeRadarMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }
    }
}
