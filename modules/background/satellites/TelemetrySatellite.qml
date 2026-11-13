import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../theme"

Item {
    id: telemetrySatellite

    property real orbitDistance: 2.10
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

    property real baselineDepthScale: 0.75 + (Math.max(0.0, proj.z) * 0.25)
    property real centerFocusFactor:  (proj.z > 0) ? Math.max(0.0, 1.0 - (Math.abs(proj.x) * 1.6)) : 0.0
    scale: (baselineDepthScale + (centerFocusFactor * 0.18)) * 1.45 * satelliteZoom
    Behavior on scale {
        enabled: !telemetrySatellite.pressed
        NumberAnimation { duration: 500; easing.type: Easing.OutBack }
    }

    width:  165
    height: 210

    property real xNorm: proj.x / orbitDistance
    property real yNorm: proj.y / orbitDistance

    transform: [
        Rotation {
            axis { x: 1; y: 0; z: 0 }
            angle: -telemetrySatellite.yNorm * 60
            origin.x: telemetrySatellite.width / 2
            origin.y: telemetrySatellite.height / 2
        },
        Rotation {
            axis { x: 0; y: 1; z: 0 }
            angle: telemetrySatellite.xNorm * 55
            origin.x: telemetrySatellite.width / 2
            origin.y: telemetrySatellite.height / 2
        }
    ]

    Column {
        id: satelliteVerticalChassis
        anchors.centerIn: parent; spacing: 4

        Item {
            width: 36; height: 38
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent; radius: 4
                color: theme.crust; border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.15); border.width: 1
                transform: Translate { x: -telemetrySatellite.xNorm * 10; y: telemetrySatellite.yNorm * 10 }
            }
            Rectangle {
                anchors.fill: parent; radius: 4
                color: theme.mantle; border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.25); border.width: 1
                transform: Translate { x: -telemetrySatellite.xNorm * 5; y: telemetrySatellite.yNorm * 5 }
            }
            Rectangle {
                anchors.fill: parent; radius: 4
                color: theme.mantle
                border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                border.width: 1
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.12); anchors.centerIn: parent }
                Rectangle { width: 1; height: parent.height; color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.12); anchors.centerIn: parent }
            }
        }

        Rectangle { width: 2; height: 6; anchors.horizontalCenter: parent.horizontalCenter; color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.5) }

        Item {
            width: 120; height: 64
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                id: telemetryExhaust
                width: 50; height: 30
                anchors.horizontalCenter: centralCoreChassis.horizontalCenter
                anchors.top: centralCoreChassis.bottom
                anchors.topMargin: -2
                z: -1
                opacity: 0.25 + Math.sin(telemetrySatellite.independentCometAngle * 4 + 2) * 0.05
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.35) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Rectangle {
                width: 120; height: 64; radius: 12
                color: theme.crust; border.color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.2); border.width: 1.2
                transform: Translate { x: -telemetrySatellite.xNorm * 10; y: telemetrySatellite.yNorm * 10 }
            }
            Rectangle {
                width: 120; height: 64; radius: 12
                color: theme.mantle; border.color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.35); border.width: 1.2
                transform: Translate { x: -telemetrySatellite.xNorm * 5; y: telemetrySatellite.yNorm * 5 }
            }
            Rectangle {
                id: centralCoreChassis
                anchors.fill: parent
                color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.94)
                border.color: telemetrySatellite.centerFocusFactor > 0
                    ? Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.5)
                    : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.5)
                border.width: 1.2; radius: 12
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    spacing: 3
                    anchors.top: parent.top; anchors.topMargin: 5
                    anchors.left: parent.left; anchors.leftMargin: 7
                    Rectangle { width: 3; height: 3; radius: 1.5; color: theme.blue
                        SequentialAnimation on opacity { loops: Animation.Infinite; running: true
                            NumberAnimation { from: 1; to: 0.1; duration: 250 }
                            NumberAnimation { from: 0.1; to: 1; duration: 250 }
                            PauseAnimation { duration: 600 }
                        }
                    }
                    Rectangle { width: 3; height: 3; radius: 1.5; color: theme.teal
                        SequentialAnimation on opacity { loops: Animation.Infinite; running: true
                            PauseAnimation { duration: 300 }
                            NumberAnimation { from: 1; to: 0.0; duration: 350 }
                            NumberAnimation { from: 0.0; to: 1; duration: 350 }
                        }
                    }
                }

                Grid {
                    id: workspaceBlockGrid
                    anchors.centerIn: parent; anchors.verticalCenterOffset: 1
                    columns: 4; spacing: 4

                    Repeater {
                        model: 8
                        delegate: Rectangle {
                            id: wsBlock
                            readonly property int wsId: index + 1
                            readonly property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                            readonly property bool isOccupied: {
                                const list = Hyprland.workspaces.values;
                                for (let i = 0; i < list.length; i++) {
                                    if (list[i].id === wsId) return true;
                                }
                                return false;
                            }

                            width: 22; height: 18; radius: 4
                            color: isActive
                                ? theme.mauve
                                : (isOccupied
                                    ? Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.12)
                                    : "transparent")
                            border.color: isActive
                                ? "transparent"
                                : (isOccupied
                                    ? Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.3)
                                    : Qt.rgba(theme.overlay0.r, theme.overlay0.g, theme.overlay0.b, 0.2))
                            border.width: 1

                            Behavior on color        { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            scale: wsPressArea.pressed ? 0.88 : (wsPressArea.containsMouse && !isActive ? 1.12 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }

                            Text {
                                anchors.centerIn: parent
                                text: wsId.toString()
                                font.family: "JetBrains Mono"; font.pixelSize: 10
                                font.weight: isActive ? Font.Bold : Font.Normal
                                color: isActive
                                    ? theme.crust
                                    : (isOccupied ? theme.text : theme.overlay0)
                            }

                            MouseArea {
                                id: wsPressArea
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("workspace " + wsId)
                            }
                        }
                    }
                }
            }
        }

        Rectangle { width: 2; height: 6; anchors.horizontalCenter: parent.horizontalCenter; color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.5) }

        Item {
            width: 32; height: 34
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: 32; height: 34; radius: 4
                color: theme.crust; border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.15); border.width: 1
                transform: Translate { x: -telemetrySatellite.xNorm * 10; y: telemetrySatellite.yNorm * 10 }
            }
            Rectangle {
                width: 32; height: 34; radius: 4
                color: theme.mantle; border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.25); border.width: 1
                transform: Translate { x: -telemetrySatellite.xNorm * 5; y: telemetrySatellite.yNorm * 5 }
            }
            Rectangle {
                id: telemetryBottomPanel
                anchors.fill: parent
                color: theme.mantle
                border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                border.width: 1; radius: 4
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.12); anchors.centerIn: parent }
                Rectangle { width: 1; height: parent.height; color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.12); anchors.centerIn: parent }
            }
        }
    }
}
