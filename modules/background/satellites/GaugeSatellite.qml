import QtQuick
import "../../../theme"

Item {
    id: gaugeSatellite

    property real orbitDistance: 2.20
    property real angle: 0
    property real gaugeBaseY: 0.15
    property var proj: ({ x: 0, y: 0, z: 0 })
    property real originX: parent ? parent.width / 2 : 0
    property real originY: parent ? parent.height / 2 : 0
    property real earthZ: -100000
    property real earthSphereRadius: 1150
    property real satelliteZoom: 1.0
    property bool isSearchMode: false
    property bool weatherRingsActive: false
    property bool pressed: false
    property real independentCometAngle: 0
    property var detailedWeatherData: null

    MatugenColors { id: theme }

    x: originX + (proj.x * earthSphereRadius) - width / 2
    y: originY + (proj.y * earthSphereRadius) - height / 2
    z: earthZ + Math.round(proj.z * 1000)

    opacity: isSearchMode ? 0.0 : (weatherRingsActive ? 1.0 : 0.0)
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 400 } }

    property real baselineDepthScale: 0.72 + (Math.max(0.0, proj.z) * 0.25)
    property real centerFocusFactor:  (proj.z > 0) ? Math.max(0.0, 1.0 - (Math.abs(proj.x) * 1.6)) : 0.0
    scale: (weatherRingsActive ? ((baselineDepthScale + (centerFocusFactor * 0.12)) * 2.2) : 1.30) * satelliteZoom
    Behavior on scale {
        enabled: !gaugeSatellite.pressed
        NumberAnimation { duration: 500; easing.type: Easing.OutBack }
    }

    width: 260
    height: 100

    property real xNorm: proj.x / orbitDistance
    property real yNorm: proj.y / orbitDistance

    transform: [
        Rotation {
            axis { x: 1; y: 0; z: 0 }
            angle: -gaugeSatellite.yNorm * 55
            origin.x: gaugeSatellite.width / 2
            origin.y: gaugeSatellite.height / 2
        },
        Rotation {
            axis { x: 0; y: 1; z: 0 }
            angle: gaugeSatellite.xNorm * 60
            origin.x: gaugeSatellite.width / 2
            origin.y: gaugeSatellite.height / 2
        }
    ]

    Rectangle {
        id: gaugeExhaust
        width: 70; height: 30
        anchors.horizontalCenter: gaugeCoreChassis.horizontalCenter
        anchors.top: gaugeCoreChassis.bottom
        anchors.topMargin: -2
        z: -1
        opacity: 0.25 + Math.sin(gaugeSatellite.independentCometAngle * 4 + 1) * 0.05
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.35) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        width: 190; height: 86; anchors.centerIn: parent; radius: 14
        color: theme.crust; border.color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.2); border.width: 1.2
        transform: Translate { x: -gaugeSatellite.xNorm * 10; y: gaugeSatellite.yNorm * 10 }
    }
    Rectangle {
        width: 190; height: 86; anchors.centerIn: parent; radius: 14
        color: theme.mantle; border.color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.35); border.width: 1.2
        transform: Translate { x: -gaugeSatellite.xNorm * 5; y: gaugeSatellite.yNorm * 5 }
    }
    Rectangle {
        id: gaugeCoreChassis
        width: 190; height: 86
        anchors.centerIn: parent
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.94)
        border.color: gaugeSatellite.centerFocusFactor > 0
            ? Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.55)
            : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.5)
        border.width: 1.2; radius: 14
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 4; height: 4; radius: 2; color: theme.peach
            anchors.top: parent.top; anchors.topMargin: 6
            anchors.right: parent.right; anchors.rightMargin: 8
            SequentialAnimation on opacity { loops: Animation.Infinite; running: true
                NumberAnimation { from: 1; to: 0.15; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.15; to: 1; duration: 900; easing.type: Easing.InOutSine }
            }
        }

        Grid {
            anchors.centerIn: parent
            columns: 2; rows: 2; spacing: 6

            Rectangle {
                width: 82; height: 32; radius: 8
                color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.5)
                Row {
                    anchors.centerIn: parent; spacing: 6
                    Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: theme.blue; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: ((gaugeSatellite.detailedWeatherData && gaugeSatellite.detailedWeatherData.forecast && gaugeSatellite.detailedWeatherData.forecast[0]) ? gaugeSatellite.detailedWeatherData.forecast[0].wind + "m/s" : "--")
                        font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.Black; color: theme.text; anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: 82; height: 32; radius: 8
                color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.5)
                Row {
                    anchors.centerIn: parent; spacing: 6
                    Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: theme.teal; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: ((gaugeSatellite.detailedWeatherData && gaugeSatellite.detailedWeatherData.forecast && gaugeSatellite.detailedWeatherData.forecast[0]) ? gaugeSatellite.detailedWeatherData.forecast[0].humidity + "%" : "--")
                        font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.Black; color: theme.text; anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: 82; height: 32; radius: 8
                color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.5)
                Row {
                    anchors.centerIn: parent; spacing: 6
                    Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: theme.mauve; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: ((gaugeSatellite.detailedWeatherData && gaugeSatellite.detailedWeatherData.forecast && gaugeSatellite.detailedWeatherData.forecast[0]) ? gaugeSatellite.detailedWeatherData.forecast[0].pop + "%" : "--")
                        font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.Black; color: theme.text; anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: 82; height: 32; radius: 8
                color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.5)
                Row {
                    anchors.centerIn: parent; spacing: 6
                    Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: theme.peach; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: ((gaugeSatellite.detailedWeatherData && gaugeSatellite.detailedWeatherData.forecast && gaugeSatellite.detailedWeatherData.forecast[0]) ? gaugeSatellite.detailedWeatherData.forecast[0].feels_like + "°" : "--")
                        font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.Black; color: theme.text; anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    Rectangle {
        width: 26; height: 44; anchors.right: gaugeCoreChassis.left; anchors.rightMargin: 5; anchors.verticalCenter: gaugeCoreChassis.verticalCenter
        color: theme.crust; border.color: Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.15); border.width: 1; radius: 4
        transform: Translate { x: -gaugeSatellite.xNorm * 10; y: gaugeSatellite.yNorm * 10 }
    }
    Rectangle {
        width: 26; height: 44; anchors.right: gaugeCoreChassis.left; anchors.rightMargin: 5; anchors.verticalCenter: gaugeCoreChassis.verticalCenter
        color: theme.mantle; border.color: Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.25); border.width: 1; radius: 4
        transform: Translate { x: -gaugeSatellite.xNorm * 5; y: gaugeSatellite.yNorm * 5 }
    }
    Rectangle {
        width: 26; height: 44; anchors.right: gaugeCoreChassis.left; anchors.rightMargin: 5; anchors.verticalCenter: gaugeCoreChassis.verticalCenter
        color: theme.mantle; border.color: Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.35); border.width: 1; radius: 4
        Grid { anchors.fill: parent; anchors.margins: 4; columns: 2; spacing: 2
            Repeater { model: 4; Rectangle { width: 8; height: 17; color: Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.15); radius: 2 } }
        }
    }

    Rectangle {
        width: 26; height: 44; anchors.left: gaugeCoreChassis.right; anchors.leftMargin: 5; anchors.verticalCenter: gaugeCoreChassis.verticalCenter
        color: theme.crust; border.color: Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.15); border.width: 1; radius: 4
        transform: Translate { x: -gaugeSatellite.xNorm * 10; y: gaugeSatellite.yNorm * 10 }
    }
    Rectangle {
        width: 26; height: 44; anchors.left: gaugeCoreChassis.right; anchors.leftMargin: 5; anchors.verticalCenter: gaugeCoreChassis.verticalCenter
        color: theme.mantle; border.color: Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.25); border.width: 1; radius: 4
        transform: Translate { x: -gaugeSatellite.xNorm * 5; y: gaugeSatellite.yNorm * 5 }
    }
    Rectangle {
        width: 26; height: 44; anchors.left: gaugeCoreChassis.right; anchors.leftMargin: 5; anchors.verticalCenter: gaugeCoreChassis.verticalCenter
        color: theme.mantle; border.color: Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.35); border.width: 1; radius: 4
        Grid { anchors.fill: parent; anchors.margins: 4; columns: 2; spacing: 2
            Repeater { model: 4; Rectangle { width: 8; height: 17; color: Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.15); radius: 2 } }
        }
    }
}
