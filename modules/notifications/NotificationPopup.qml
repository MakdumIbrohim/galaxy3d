import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../../theme"

PanelWindow {
    id: notifWin

    anchors {
        top: true
        right: true
    }

    implicitWidth: 360
    implicitHeight: notifCol.implicitHeight + 32

    WlrLayershell.namespace: "galaxy3d-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    MatugenColors { id: theme }

    NotificationServer {
        id: server
    }

    ColumnLayout {
        id: notifCol
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 56
        anchors.rightMargin: 16
        spacing: 10
        width: 330

        Repeater {
            model: server.trackedNotifications

            delegate: Rectangle {
                id: card
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: cardLayout.implicitHeight + 20
                radius: 14
                color: Qt.rgba(0.08, 0.08, 0.12, 0.90)
                border.color: cardMa.containsMouse ? theme.mauve : Qt.rgba(1, 1, 1, 0.15)
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: cardMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.modelData.dismiss()
                }

                RowLayout {
                    id: cardLayout
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        width: 36
                        height: 36
                        radius: 8
                        color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.5)

                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: card.modelData.appIcon
                                ? (card.modelData.appIcon.startsWith("/") ? "file://" + card.modelData.appIcon : "image://icon/" + card.modelData.appIcon)
                                : "image://icon/dialog-information"
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰂚"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 16
                            color: theme.blue
                            visible: !card.modelData.appIcon
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: card.modelData.appName || "Notification"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: theme.subtext0
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "󰅖"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 12
                                color: theme.overlay0

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: card.modelData.dismiss()
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.summary
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: theme.text
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.body
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.75)
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                    }
                }
            }
        }
    }
}
