import QtQuick
import QtQuick.Shapes
import "../../../theme"

Item {
    id: root
    anchors.fill: parent

    MatugenColors { id: colors }

    property real meteorProgress: 0.0
    property real meteorOpacity: 0.0
    property real startX: 0
    property real startY: 0
    property real endX: 0
    property real endY: 0
    property real meteorLength: 160
    property real meteorAngleDeg: 42
    property bool isDual: false

    SequentialAnimation {
        id: meteorAnim

        ParallelAnimation {
            NumberAnimation { target: root; property: "meteorProgress"; from: 0.0; to: 1.0; duration: 850; easing.type: Easing.OutQuad }
            SequentialAnimation {
                NumberAnimation { target: root; property: "meteorOpacity"; from: 0.0; to: 0.95; duration: 180; easing.type: Easing.OutQuad }
                PauseAnimation { duration: 320 }
                NumberAnimation { target: root; property: "meteorOpacity"; from: 0.95; to: 0.0; duration: 350; easing.type: Easing.InQuad }
            }
        }

        ScriptAction {
            script: {
                root.scheduleNextMeteor();
            }
        }
    }

    Timer {
        id: spawnTimer
        interval: 12000
        repeat: false
        running: true
        onTriggered: root.launchMeteor()
    }

    function scheduleNextMeteor() {
        // Random interval between 10 to 24 seconds
        spawnTimer.interval = 10000 + Math.random() * 14000;
        spawnTimer.restart();
    }

    function launchMeteor() {
        // Launch from upper area traveling down-left or down-right
        let goLeft = Math.random() > 0.4;
        let angle = goLeft ? (135 + (Math.random() * 20 - 10)) : (45 + (Math.random() * 20 - 10));
        root.meteorAngleDeg = angle;
        root.meteorLength = 140 + Math.random() * 90;
        root.isDual = Math.random() > 0.65;

        let rad = angle * Math.PI / 180;
        let dist = 600 + Math.random() * 400;

        root.startX = Math.random() * root.width * 0.8 + root.width * 0.1;
        root.startY = Math.random() * (root.height * 0.35);

        root.endX = root.startX + Math.cos(rad) * dist;
        root.endY = root.startY + Math.sin(rad) * dist;

        meteorAnim.restart();
    }

    // Primary Meteor Streak
    Item {
        id: streak
        visible: root.meteorOpacity > 0.01
        opacity: root.meteorOpacity

        readonly property real curX: root.startX + (root.endX - root.startX) * root.meteorProgress
        readonly property real curY: root.startY + (root.endY - root.startY) * root.meteorProgress

        x: curX
        y: curY

        // Luminous Core Head
        Rectangle {
            anchors.centerIn: parent
            width: 3.5; height: 3.5
            radius: 1.75
            color: "#ffffff"
        }

        // Plasma Glow Corona
        Rectangle {
            anchors.centerIn: parent
            width: 9; height: 9
            radius: 4.5
            color: Qt.alpha(colors.blue, 0.45)
        }

        // Vapor Trail
        Shape {
            anchors.centerIn: parent
            width: root.meteorLength; height: 6
            rotation: root.meteorAngleDeg + 180
            transformOrigin: Item.Left

            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: 0
                    x2: root.meteorLength; y2: 0
                    GradientStop { position: 0.0; color: Qt.alpha(colors.blue, 0.75) }
                    GradientStop { position: 0.35; color: Qt.alpha(colors.teal, 0.35) }
                    GradientStop { position: 1.0; color: "transparent" }
                }

                startX: 0; startY: 1
                PathLine { x: root.meteorLength; y: 2.5 }
                PathLine { x: root.meteorLength; y: 3.5 }
                PathLine { x: 0; y: 5 }
            }
        }
    }

    // Secondary Micro-Meteor (Dual Burst)
    Item {
        id: dualStreak
        visible: root.isDual && root.meteorOpacity > 0.01
        opacity: root.meteorOpacity * 0.7

        readonly property real curX: (root.startX - 40) + (root.endX - root.startX) * (root.meteorProgress * 0.95)
        readonly property real curY: (root.startY + 25) + (root.endY - root.startY) * (root.meteorProgress * 0.95)

        x: curX
        y: curY

        Rectangle {
            anchors.centerIn: parent
            width: 2.2; height: 2.2
            radius: 1.1
            color: "#ffffff"
        }

        Shape {
            anchors.centerIn: parent
            width: root.meteorLength * 0.65; height: 4
            rotation: root.meteorAngleDeg + 180
            transformOrigin: Item.Left

            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: 0
                    x2: root.meteorLength * 0.65; y2: 0
                    GradientStop { position: 0.0; color: Qt.alpha(colors.teal, 0.5) }
                    GradientStop { position: 1.0; color: "transparent" }
                }

                startX: 0; startY: 1
                PathLine { x: root.meteorLength * 0.65; y: 2 }
                PathLine { x: 0; y: 3 }
            }
        }
    }
}
