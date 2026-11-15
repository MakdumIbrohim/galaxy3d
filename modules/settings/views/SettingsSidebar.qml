import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    required property var theme
    required property var categories
    property int activeCategoryIndex: 0
    signal categorySelected(int index)
    signal closeRequested()

    color: Qt.rgba(root.theme.crust.r, root.theme.crust.g, root.theme.crust.b, 0.75)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Sidebar Brand Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 36
                height: 36
                radius: 10
                color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.18)
                border.color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.4)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 18
                    color: root.theme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                RowLayout {
                    spacing: 6
                    Text {
                        text: "CONTROL DECK"
                        font.family: "JetBrains Mono"
                        font.weight: Font.Bold
                        font.pixelSize: 12
                        color: root.theme.text
                    }
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: "#a6e3a1"
                    }
                }

                Text {
                    text: "GALAXY // SYSTEM PREFS"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    color: root.theme.overlay0
                }
            }
        }

        Rectangle {
            height: 1
            Layout.fillWidth: true
            color: Qt.rgba(root.theme.surface1.r, root.theme.surface1.g, root.theme.surface1.b, 0.5)
        }

        // Category List
        ListView {
            id: catListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.categories
            spacing: 4
            clip: true

            delegate: Rectangle {
                readonly property bool isSelected: root.activeCategoryIndex === index
                width: catListView.width
                height: 42
                radius: 10
                color: isSelected
                    ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.18)
                    : (catMa.containsMouse ? Qt.rgba(root.theme.surface1.r, root.theme.surface1.g, root.theme.surface1.b, 0.45) : "transparent")
                border.color: isSelected
                    ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.5)
                    : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        width: 3.5
                        height: 18
                        radius: 2
                        color: isSelected ? root.theme.accent : "transparent"
                    }

                    Text {
                        text: modelData.icon
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 15
                        color: isSelected ? root.theme.accent : root.theme.subtext0
                    }

                    Text {
                        text: modelData.name
                        font.family: "JetBrains Mono"
                        font.weight: isSelected ? Font.Bold : Font.Normal
                        font.pixelSize: 11
                        color: isSelected ? root.theme.text : root.theme.subtext0
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: catMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.categorySelected(index)
                }
            }
        }

        // Bottom Close Settings Button
        Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: 10
            color: sidebarCloseMa.containsMouse
                ? Qt.rgba(root.theme.red.r, root.theme.red.g, root.theme.red.b, 0.22)
                : Qt.rgba(root.theme.surface0.r, root.theme.surface0.g, root.theme.surface0.b, 0.6)
            border.color: sidebarCloseMa.containsMouse
                ? root.theme.red
                : Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: "󰅖"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 14
                    color: sidebarCloseMa.containsMouse ? root.theme.red : root.theme.subtext0
                }
                Text {
                    text: "Close Settings"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.bold: true
                    color: sidebarCloseMa.containsMouse ? root.theme.text : root.theme.subtext0
                }
            }

            MouseArea {
                id: sidebarCloseMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }
    }
}
