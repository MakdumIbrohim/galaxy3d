import QtQuick
import "../../../theme"

Item {
    id: easterEggSatellite

    property real orbitDistance: 1.15
    property real angle: 0
    property var proj: ({ x: 0, y: 0, z: 0 })
    property real sphereRadius: 260
    property real satelliteZoom: 1.0
    property bool isSearchMode: false
    property bool pressed: false
    property real centerWidth: parent ? parent.width : 520
    property real centerHeight: parent ? parent.height : 520
    property real independentCometAngle: 0

    MatugenColors { id: theme }

    x: (centerWidth / 2) + (proj.x * sphereRadius) - width / 2
    y: (centerHeight / 2) + (proj.y * sphereRadius) - height / 2
    z: Math.round(proj.z * 1000)

    opacity: isSearchMode ? 0.0 : 1.0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 300 } }

    property real baselineDepthScale: 0.70 + (Math.max(0.0, proj.z) * 0.25)
    property real centerFocusFactor:  (proj.z > 0) ? Math.max(0.0, 1.0 - (Math.abs(proj.x) * 1.6)) : 0.0
    scale: (baselineDepthScale + (centerFocusFactor * 0.12)) * 1.3 * satelliteZoom
    Behavior on scale {
        enabled: !easterEggSatellite.pressed
        NumberAnimation { duration: 500; easing.type: Easing.OutBack }
    }

    width:  80
    height: 70

    property real xNorm: proj.x / orbitDistance
    property real yNorm: proj.y / orbitDistance

    transform: [
        Rotation {
            axis { x: 1; y: 0; z: 0 }
            angle: -easterEggSatellite.yNorm * 55
            origin.x: easterEggSatellite.width / 2
            origin.y: easterEggSatellite.height / 2
        },
        Rotation {
            axis { x: 0; y: 1; z: 0 }
            angle: easterEggSatellite.xNorm * 60
            origin.x: easterEggSatellite.width / 2
            origin.y: easterEggSatellite.height / 2
        }
    ]

    Rectangle {
        id: eggExhaust
        width: 30; height: 20
        anchors.horizontalCenter: eggChassis.horizontalCenter
        anchors.top: eggChassis.bottom
        anchors.topMargin: -2
        z: -1
        opacity: 0.25 + Math.sin(easterEggSatellite.independentCometAngle * 4 + 5) * 0.05
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.35) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        id: eggLeftWing
        anchors.right: eggChassis.left; anchors.rightMargin: 4
        anchors.verticalCenter: eggChassis.verticalCenter
        width: 14; height: 24; color: theme.mantle
        border.color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.4)
        border.width: 1; radius: 2
        Grid {
            anchors.fill: parent; anchors.margins: 2; columns: 2; rows: 3; spacing: 1
            Repeater {
                model: 6
                Rectangle {
                    width:  (eggLeftWing.width  - 5) / 2
                    height: (eggLeftWing.height - 6) / 3
                    color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, index % 2 === 0 ? 0.25 : 0.1)
                }
            }
        }
    }

    Rectangle {
        width: 50; height: 40; anchors.centerIn: parent; radius: 8
        color: theme.crust; border.color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.2); border.width: 1.2
        transform: Translate { x: -easterEggSatellite.xNorm * 8; y: easterEggSatellite.yNorm * 8 }
    }
    Rectangle {
        width: 50; height: 40; anchors.centerIn: parent; radius: 8
        color: theme.mantle; border.color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.35); border.width: 1.2
        transform: Translate { x: -easterEggSatellite.xNorm * 4; y: easterEggSatellite.yNorm * 4 }
    }
    Rectangle {
        id: eggChassis
        anchors.centerIn: parent
        width: 50; height: 40
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.94)
        border.color: easterEggSatellite.centerFocusFactor > 0
            ? Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.6)
            : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.5)
        border.width: 1.2; radius: 8
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 3; height: 3; radius: 1.5; color: theme.mauve
            anchors.top: parent.top; anchors.topMargin: 4
            anchors.right: parent.right; anchors.rightMargin: 5
            SequentialAnimation on opacity {
                loops: Animation.Infinite; running: true
                NumberAnimation { from: 1; to: 0.2; duration: 500; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.2; to: 1; duration: 500; easing.type: Easing.InOutSine }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 2

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 18; height: 18
                source: "/usr/share/icons/cachyos.svg"
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "sup, vaxry"
                font.family: "JetBrains Mono"
                font.pixelSize: 7
                font.weight: Font.Black
                color: theme.text
            }
        }
    }

    Rectangle {
        id: eggRightWing
        anchors.left: eggChassis.right; anchors.leftMargin: 4
        anchors.verticalCenter: eggChassis.verticalCenter
        width: 14; height: 24; color: theme.mantle
        border.color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.4)
        border.width: 1; radius: 2
        Grid {
            anchors.fill: parent; anchors.margins: 2; columns: 2; rows: 3; spacing: 1
            Repeater {
                model: 6
                Rectangle {
                    width:  (eggRightWing.width  - 5) / 2
                    height: (eggRightWing.height - 6) / 3
                    color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, index % 2 === 0 ? 0.25 : 0.1)
                }
            }
        }
    }
}
