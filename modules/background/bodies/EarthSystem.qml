import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../../theme"

Item {
    id: root

    property var earthProj: ({ x: 0, y: 0, z: 0 })
    property real earthZoom: 1.0
    property real mouseShiftX: 0
    property real mouseShiftY: 0
    property string weatherIcon: "󰖐"
    property string weatherTemp: "--°"
    property string weatherHex: theme.yellow
    property bool weatherRingsActive: false
    property string timeStr: "00:00:00"
    property string fullDateStr: "----"
    property real sunValueX: 1.0
    property real sunValueY: 0.0
    property real screenSunAngleDeg: 0
    property var detailedWeatherData: null
    property real independentCometAngle: 0
    property real weatherRingPhaseOffset: 0
    property real baseSphereRadius: 260
    property real earthSphereRadius: 1150
    property real satelliteZoom: 1.0
    property bool scenePressed: false
    property var project3DFunc: null

    signal toggleWeatherRequested()

    MatugenColors { id: theme }

    Rectangle {
        id: earthBase
        width: 1350 * root.earthZoom
        height: 1350 * root.earthZoom
        radius: width / 2
        color: "#01030a"

        x: -width * 0.40 - (root.mouseShiftX * 25)
        y: (parent.height - height) / 2 - (root.mouseShiftY * 20)
        z: -100000

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: earthBase.width
                height: earthBase.height
                radius: width / 2
            }
        }

        Item {
            anchors.fill: parent
            Image {
                id: earthTexture
                width: parent.width; height: parent.height
                x: 0
                y: 0
                source: "../../../assets/earth.jpg"
                fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            z: 1
            scale: root.earthZoom
            spacing: 4

            Item {
                id: weatherTriggerContainer
                Layout.alignment: Qt.AlignHCenter
                width: weatherRow.implicitWidth
                height: weatherRow.implicitHeight

                RowLayout {
                    id: weatherRow
                    spacing: 10
                    Text {
                        text: root.weatherIcon !== "" ? root.weatherIcon : "󰖐"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 28
                        color: root.weatherHex
                    }
                    Text {
                        text: root.weatherTemp !== "" ? root.weatherTemp : "--°"
                        font.family: "JetBrains Mono"
                        font.weight: Font.Black
                        font.pixelSize: 28
                        color: theme.text
                    }
                }

                MouseArea {
                    id: weatherToggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleWeatherRequested()
                }
            }

            Text {
                text: root.timeStr !== "" ? root.timeStr : "00:00:00"
                font.family: "JetBrains Mono"
                font.weight: Font.Black
                font.pixelSize: 160
                color: theme.text
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: root.fullDateStr !== "" ? root.fullDateStr.toUpperCase() : "----"
                font.family: "JetBrains Mono"
                font.weight: Font.Black
                font.pixelSize: 42
                color: theme.text
                Layout.alignment: Qt.AlignHCenter
            }
        }

        RadialGradient {
            anchors.fill: parent
            z: 2
            horizontalOffset: root.sunValueX * (parent.width * 0.45)
            verticalOffset:  -root.sunValueY * (parent.height * 0.45)
            horizontalRadius: parent.width * 0.72
            verticalRadius:   parent.height * 0.72
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.68; color: Qt.rgba(0, 0, 1/255, 0.55) }
                GradientStop { position: 0.82; color: Qt.rgba(0, 0, 0, 0.88) }
                GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.96) }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            z: 3
            rotation: root.screenSunAngleDeg + 90
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.38; color: "transparent" }
                GradientStop { position: 0.46; color: Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.18) }
                GradientStop { position: 0.50; color: Qt.rgba(theme.blue.r,  theme.blue.g,  theme.blue.b,  0.22) }
                GradientStop { position: 0.54; color: Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.10) }
                GradientStop { position: 0.62; color: "transparent" }
                GradientStop { position: 1.0;  color: "transparent" }
            }
        }

        RadialGradient {
            anchors.fill: parent
            z: 3
            horizontalOffset: root.sunValueX * (parent.width * 0.3)
            verticalOffset: root.sunValueY * (parent.height * 0.3)
            horizontalRadius: parent.width * 0.8
            verticalRadius: parent.height * 0.8
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.2) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            z: 4
            rotation: root.screenSunAngleDeg + 180
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.6) }
                GradientStop { position: 0.04; color: Qt.rgba(theme.sapphire.r, theme.sapphire.g, theme.sapphire.b, 0.35) }
                GradientStop { position: 0.12; color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.08) }
                GradientStop { position: 0.25; color: "transparent" }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            rotation: root.screenSunAngleDeg
            z: 4
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(theme.sapphire.r, theme.sapphire.g, theme.sapphire.b, 0.2) }
                GradientStop { position: 0.06; color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.05) }
                GradientStop { position: 0.2; color: "transparent" }
            }
        }

        Rectangle {
            anchors.fill: parent; radius: width / 2; z: 4
            gradient: Gradient { orientation: Gradient.Vertical
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.42; color: Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.04) }
                GradientStop { position: 0.50; color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.07) }
                GradientStop { position: 0.58; color: Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.04) }
                GradientStop { position: 1.0;  color: "transparent" }
            }
        }
    }

    Repeater {
        model: (root.weatherRingsActive && root.detailedWeatherData && root.detailedWeatherData.forecast && root.detailedWeatherData.forecast[0] && root.detailedWeatherData.forecast[0].hourly)
               ? root.detailedWeatherData.forecast[0].hourly.slice(0, 8)
               : []

        delegate: Item {
            id: weatherNode

            property real orbitDistance: 1.65
            property real baseAngle: (index * (2 * Math.PI / 8))
            property real angle: baseAngle + root.independentCometAngle + root.weatherRingPhaseOffset

            property real b_x: Math.cos(angle) * orbitDistance
            property real b_z: Math.sin(angle) * orbitDistance
            property real b_y: Math.sin(index * Math.PI / 4) * 0.12

            property var proj: (root.project3DFunc && typeof root.project3DFunc === "function")
                               ? root.project3DFunc(b_x, b_y, b_z, true)
                               : ({ x: 0, y: 0, z: 0 })

            x: (parent.width / 2) + (root.earthProj.x * root.baseSphereRadius) + (proj.x * root.earthSphereRadius) - width / 2
            y: (parent.height / 2) + (root.earthProj.y * root.baseSphereRadius) + (proj.y * root.earthSphereRadius) - height / 2
            z: earthBase.z + Math.round(proj.z * 1000)

            opacity: root.weatherRingsActive ? (proj.z < -0.1 ? 0.35 : 1.0) : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 450 } }

            property real baselineDepthScale: 0.55 + (Math.max(0.0, proj.z) * 0.40)
            scale: (root.weatherRingsActive ? baselineDepthScale : 0.2) * root.satelliteZoom * 1.6
            Behavior on scale {
                enabled: !root.scenePressed
                NumberAnimation { duration: 550; easing.type: Easing.OutBack }
            }

            width: 110; height: 48

            property real xNorm: proj.x / orbitDistance
            property real yNorm: proj.y / orbitDistance

            transform: [
                Rotation {
                    axis { x: 1; y: 0; z: 0 }
                    angle: -weatherNode.yNorm * 55
                    origin.x: weatherNode.width / 2
                    origin.y: weatherNode.height / 2
                },
                Rotation {
                    axis { x: 0; y: 1; z: 0 }
                    angle: weatherNode.xNorm * 60
                    origin.x: weatherNode.width / 2
                    origin.y: weatherNode.height / 2
                }
            ]

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: theme.crust
                border.color: modelData.hex ? Qt.rgba(parseInt(modelData.hex.slice(1,3), 16) / 255, parseInt(modelData.hex.slice(3,5), 16) / 255, parseInt(modelData.hex.slice(5,7), 16) / 255, 0.4) : Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.3)
                border.width: 1.5
                transform: Translate { x: -weatherNode.xNorm * 8; y: weatherNode.yNorm * 8 }
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: theme.mantle
                border.color: modelData.hex ? Qt.rgba(parseInt(modelData.hex.slice(1,3), 16) / 255, parseInt(modelData.hex.slice(3,5), 16) / 255, parseInt(modelData.hex.slice(5,7), 16) / 255, 0.5) : Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.4)
                border.width: 1.5
                transform: Translate { x: -weatherNode.xNorm * 4; y: weatherNode.yNorm * 4 }
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.92)
                border.color: modelData.hex
                    ? Qt.rgba(
                        parseInt(modelData.hex.slice(1,3), 16) / 255,
                        parseInt(modelData.hex.slice(3,5), 16) / 255,
                        parseInt(modelData.hex.slice(5,7), 16) / 255,
                        0.6)
                    : Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.5)
                border.width: 1.5

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10; anchors.rightMargin: 10
                    spacing: 6
                    Text {
                        text: modelData ? modelData.time : ""
                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 10
                        color: theme.text
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: modelData ? modelData.icon : ""
                        font.family: "Iosevka Nerd Font"; font.pixelSize: 14
                        color: modelData.hex ? modelData.hex : theme.text
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: modelData ? modelData.temp + "°" : ""
                        font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: 12
                        color: theme.text
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
