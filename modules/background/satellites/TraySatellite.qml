import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../../theme"

Item {
    id: traySatellite

    property real orbitDistance: 2.20
    property real angle: 0
    property var proj: ({ x: 0, y: 0, z: 0 })
    property real sphereRadius: 260
    property real satelliteZoom: 1.0
    property bool isSearchMode: false
    property bool pressed: false
    property real centerWidth: parent ? parent.width : 520
    property real centerHeight: parent ? parent.height : 520
    property real independentCometAngle: 0
    property var parentWindow: null

    MatugenColors { id: theme }

    x: (centerWidth / 2) + (proj.x * sphereRadius) - width / 2
    y: (centerHeight / 2) + (proj.y * sphereRadius) - height / 2
    z: Math.round(proj.z * 1000)

    opacity: isSearchMode ? 0.0 : 1.0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 300 } }

    property real baselineDepthScale: 0.65 + (Math.max(0.0, proj.z) * 0.25)
    property real centerFocusFactor:  (proj.z > 0) ? Math.max(0.0, 1.0 - (Math.abs(proj.x) * 1.6)) : 0.0
    scale: (baselineDepthScale + (centerFocusFactor * 0.12)) * 1.45 * satelliteZoom
    Behavior on scale {
        enabled: !traySatellite.pressed
        NumberAnimation { duration: 500; easing.type: Easing.OutBack }
    }

    width:  Math.max(120, trayInnerRow.implicitWidth + 48)
    height: 56

    property real xNorm: proj.x / orbitDistance
    property real yNorm: proj.y / orbitDistance

    transform: [
        Rotation {
            axis { x: 1; y: 0; z: 0 }
            angle: -traySatellite.yNorm * 25
            origin.x: traySatellite.width / 2
            origin.y: traySatellite.height / 2
        },
        Rotation {
            axis { x: 0; y: 1; z: 0 }
            angle: traySatellite.xNorm * 35
            origin.x: traySatellite.width / 2
            origin.y: traySatellite.height / 2
        }
    ]

    Rectangle {
        id: trayExhaust
        width: 70; height: 25
        anchors.horizontalCenter: trayChassis.horizontalCenter
        anchors.top: trayChassis.bottom
        anchors.topMargin: -2
        z: -1
        opacity: 0.25 + Math.sin(traySatellite.independentCometAngle * 4 + 6) * 0.05
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.35) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        id: trayLeftWing
        anchors.right: trayChassis.left; anchors.rightMargin: 4
        anchors.verticalCenter: trayChassis.verticalCenter
        width: 20; height: 34; color: theme.mantle
        border.color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.35)
        border.width: 1; radius: 2
        Grid {
            anchors.fill: parent; anchors.margins: 2; columns: 2; rows: 3; spacing: 1
            Repeater {
                model: 6
                Rectangle {
                    width: (trayLeftWing.width - 5) / 2; height: (trayLeftWing.height - 6) / 3
                    color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, index % 2 === 0 ? 0.22 : 0.07)
                }
            }
        }
    }

    Rectangle {
        width: trayChassis.width; height: 48; anchors.centerIn: parent; radius: 14
        color: theme.crust; border.color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.2); border.width: 1.2
        transform: Translate { x: -traySatellite.xNorm * 8; y: traySatellite.yNorm * 8 }
    }
    Rectangle {
        width: trayChassis.width; height: 48; anchors.centerIn: parent; radius: 14
        color: theme.mantle; border.color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.35); border.width: 1.2
        transform: Translate { x: -traySatellite.xNorm * 4; y: traySatellite.yNorm * 4 }
    }
    Rectangle {
        id: trayChassis
        anchors.centerIn: parent
        width: parent.width - 48
        height: 48
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.94)
        border.color: traySatellite.centerFocusFactor > 0
            ? Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.55)
            : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.5)
        border.width: 1.2; radius: 14
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 4; height: 4; radius: 2; color: theme.blue
            anchors.top: parent.top; anchors.topMargin: 5
            anchors.right: parent.right; anchors.rightMargin: 7
            SequentialAnimation on opacity {
                loops: Animation.Infinite; running: true
                NumberAnimation { from: 1; to: 0.1; duration: 700; easing.type: Easing.OutSine }
                NumberAnimation { from: 0.1; to: 1; duration: 700; easing.type: Easing.OutSine }
            }
        }

        Text {
            anchors.top: parent.top; anchors.topMargin: 4
            anchors.left: parent.left; anchors.leftMargin: 8
            text: "TRAY"
            font.family: "JetBrains Mono"; font.pixelSize: 7; font.weight: Font.Black
            color: theme.overlay0
        }

        Text {
            anchors.centerIn: parent
            text: "TRAY CLEAR"
            font.family: "JetBrains Mono"
            font.pixelSize: 10
            font.weight: Font.Black
            color: theme.subtext0
            visible: SystemTray.items.length === 0
        }

        Row {
            id: trayInnerRow
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 2
            spacing: 10

            Repeater {
                model: SystemTray.items
                delegate: Item {
                    id: trayIconItem
                    width: 22; height: 22
                    anchors.verticalCenter: parent.verticalCenter

                    property bool isHovered: trayIconMouse.containsMouse

                    Image {
                        anchors.fill: parent
                        source: modelData.icon || ""
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(22, 22)
                        smooth: true
                        opacity: trayIconItem.isHovered ? 1.0 : 0.80
                        scale: trayIconMouse.pressed ? 0.85 : (trayIconItem.isHovered ? 1.18 : 1.0)
                        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    QsMenuAnchor {
                        id: trayMenuAnchor
                        anchor.window: traySatellite.parentWindow
                        anchor.item: trayIconItem
                        menu: modelData.menu
                    }

                    MouseArea {
                        id: trayIconMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                if (modelData.isMenuOnly || modelData.onlyMenu) {
                                    trayMenuAnchor.open();
                                } else if (typeof modelData.activate === "function") {
                                    modelData.activate();
                                }
                            } else if (mouse.button === Qt.MiddleButton) {
                                if (typeof modelData.secondaryActivate === "function") {
                                    modelData.secondaryActivate();
                                }
                            } else if (mouse.button === Qt.RightButton) {
                                if (modelData.menu) {
                                    trayMenuAnchor.open();
                                } else if (typeof modelData.activate === "function") {
                                    modelData.activate();
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: trayRightWing
            anchors.left: trayChassis.right; anchors.leftMargin: 4
            anchors.verticalCenter: trayChassis.verticalCenter
            width: 20; height: 34; color: theme.mantle
            border.color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.35)
            border.width: 1; radius: 2
            Grid {
                anchors.fill: parent; anchors.margins: 2; columns: 2; rows: 3; spacing: 1
                Repeater {
                    model: 6
                    Rectangle {
                        width: (trayRightWing.width - 5) / 2; height: (trayRightWing.height - 6) / 3
                        color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, index % 2 === 0 ? 0.22 : 0.07)
                    }
                }
            }
        }
    }
}
