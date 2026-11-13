import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Rectangle {
    id: root
    height: 34
    implicitWidth: wsRow.implicitWidth + 18
    radius: 17
    color: Qt.rgba(0.08, 0.08, 0.12, 0.85)
    border.color: Qt.rgba(1, 1, 1, 0.15)
    border.width: 1

    RowLayout {
        id: wsRow
        anchors.centerIn: parent
        spacing: 7

        Repeater {
            model: 5
            Rectangle {
                readonly property int wsId: index + 1
                readonly property bool isCurrent: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                width: isCurrent ? 22 : 8
                height: 8
                radius: 4
                color: isCurrent ? "#89b4fa" : Qt.rgba(1, 1, 1, 0.3)
                Behavior on width { NumberAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", wsId.toString()])
                }
            }
        }
    }
}
