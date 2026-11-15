import QtQuick

Rectangle {
    id: switchRoot
    property bool checked: false
    property color activeColor: "#cba6f7"
    property color inactiveColor: "#313244"
    property color borderColor: "#45475a"
    property color subtextColor: "#a6adc8"
    signal toggled(bool newState)

    width: 46
    height: 24
    radius: 12
    color: checked ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.45) : inactiveColor
    border.color: checked ? activeColor : Qt.rgba(borderColor.r, borderColor.g, borderColor.b, 0.6)
    border.width: 1.5

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    Rectangle {
        id: thumb
        width: 18
        height: 18
        radius: 9
        y: 3
        x: switchRoot.checked ? switchRoot.width - width - 3 : 3
        color: switchRoot.checked ? switchRoot.activeColor : switchRoot.subtextColor

        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            switchRoot.checked = !switchRoot.checked;
            switchRoot.toggled(switchRoot.checked);
        }
    }
}
