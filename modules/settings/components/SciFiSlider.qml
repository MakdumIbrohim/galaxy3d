import QtQuick

Item {
    id: sliderRoot
    property real from: 0.0
    property real to: 1.0
    property real value: 0.5
    property color trackColor: "#cba6f7"
    property color bgTrackColor: "#313244"
    signal moved(real val)

    implicitWidth: 200
    implicitHeight: 26

    readonly property real range: Math.max(0.0001, to - from)
    readonly property real normalized: Math.max(0.0, Math.min(1.0, (value - from) / range))

    Rectangle {
        id: trackBg
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 7
        radius: 3.5
        color: sliderRoot.bgTrackColor

        Rectangle {
            width: parent.width * sliderRoot.normalized
            height: parent.height
            radius: parent.radius
            color: sliderRoot.trackColor
        }
    }

    Rectangle {
        id: handle
        width: 18
        height: 18
        radius: 9
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(sliderRoot.width - width, (sliderRoot.width - width) * sliderRoot.normalized))
        color: "#ffffff"
        border.color: sliderRoot.trackColor
        border.width: 2.5
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function updateVal(mouseX) {
            var frac = Math.max(0.0, Math.min(1.0, mouseX / sliderRoot.width));
            var newVal = sliderRoot.from + frac * sliderRoot.range;
            sliderRoot.value = newVal;
            sliderRoot.moved(newVal);
        }

        onPressed: function(mouse) { updateVal(mouse.x); }
        onPositionChanged: function(mouse) {
            if (pressed) updateVal(mouse.x);
        }
    }
}
