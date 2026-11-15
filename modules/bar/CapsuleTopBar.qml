import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"

Item {
    id: root
    anchors.fill: parent

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: Qt.rgba(0.08, 0.08, 0.12, 0.85)
                border.color: Qt.rgba(1, 1, 1, 0.15)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 18
                    color: "#89b4fa"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) ShellBridge.toggleSettings();
                        else ShellBridge.toggleLauncher();
                    }
                }
            }

            WorkspacesPill {}
            MediaPill {}
        }

        ClockPill {
            anchors.centerIn: parent
        }

        SysControls {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
