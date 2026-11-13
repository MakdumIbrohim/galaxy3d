import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../theme"

PanelWindow {
    id: powerWindow
    visible: false

    WlrLayershell.namespace: "galaxy3d-power-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: powerWindow.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MatugenColors { id: theme }

    Shortcut {
        sequence: "Escape"
        enabled: powerWindow.visible
        onActivated: powerWindow.visible = false
    }

    // Dark backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.01, 0.02, 0.05, 0.75)
        opacity: powerWindow.visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        MouseArea {
            anchors.fill: parent
            onClicked: powerWindow.visible = false
        }
    }

    // Modal Card
    Rectangle {
        anchors.centerIn: parent
        width: 520
        height: 200
        radius: 20
        color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.96)
        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
        border.width: 1.5

        scale: powerWindow.visible ? 1.0 : 0.9
        opacity: powerWindow.visible ? 1.0 : 0.0
        Behavior on scale   { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: theme.red }
                Text {
                    text: "Sesi & Kontrol Daya"
                    font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 15; color: theme.text
                    Layout.fillWidth: true
                }
                Text {
                    text: "ESC untuk batal"
                    font.family: "JetBrains Mono"; font.pixelSize: 10; color: theme.overlay0
                }
            }

            // Power Action Buttons Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Repeater {
                    model: [
                        { "name": "Kunci",    "icon": "󰌾", "cmd": "hyprlock || loginctl lock-session", "col": theme.mauve },
                        { "name": "Suspend",  "icon": "󰤄", "cmd": "systemctl suspend",                   "col": theme.blue },
                        { "name": "Logout",   "icon": "󰍃", "cmd": "hyprctl dispatch exit",              "col": theme.yellow },
                        { "name": "Reboot",   "icon": "󰜉", "cmd": "systemctl reboot",                    "col": theme.peach },
                        { "name": "Matikan",  "icon": "", "cmd": "systemctl poweroff",                  "col": theme.red }
                    ]

                    delegate: Rectangle {
                        id: btnCard
                        Layout.fillWidth: true
                        height: 80
                        radius: 12
                        color: actionMa.containsMouse ? Qt.rgba(modelData.col.r, modelData.col.g, modelData.col.b, 0.20) : theme.surface0
                        border.color: actionMa.containsMouse ? modelData.col : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.25)
                        border.width: actionMa.containsMouse ? 1.5 : 1

                        scale: actionMa.pressed ? 0.94 : (actionMa.containsMouse ? 1.05 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: modelData.icon
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 24
                                color: modelData.col
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: modelData.name
                                font.family: "JetBrains Mono"
                                font.weight: Font.DemiBold
                                font.pixelSize: 11
                                color: theme.text
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: actionMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                powerWindow.visible = false;
                                Quickshell.execDetached(["bash", "-c", modelData.cmd]);
                            }
                        }
                    }
                }
            }
        }
    }
}
