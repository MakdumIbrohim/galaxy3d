import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: topBarWin

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 46
    WlrLayershell.namespace: "galaxy3d-topbar"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Auto
    color: "transparent"

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 4
        anchors.bottomMargin: 4

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

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: "/usr/share/icons/cachyos.svg"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            Quickshell.execDetached(["qs", "-c", "galaxy3d", "ipc", "call", "settings", "toggle"]);
                        } else {
                            Quickshell.execDetached(["qs", "-c", "galaxy3d", "ipc", "call", "launcher", "toggle"]);
                        }
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
