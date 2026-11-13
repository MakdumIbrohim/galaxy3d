import QtQuick
import Qt5Compat.GraphicalEffects
import "../../../theme"

Rectangle {
    id: moonBase
    anchors.fill: parent
    radius: width / 2
    color: "#111"
    z: 0

    property real rotX: 0
    property real rotY: 0
    property real camX: 0
    property real camY: 0
    property real sunValueX: 1.0
    property real sunValueY: 0.0

    MatugenColors { id: theme }

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width:  moonBase.width
            height: moonBase.height
            radius: width / 2
        }
    }

    Item {
        anchors.fill: parent
        Image {
            id: moonTexture
            width: parent.width * 2; height: parent.height * 2
            x: {
                let norm = (((moonBase.rotY + moonBase.camY) % (Math.PI * 2)) + Math.PI * 2) % (Math.PI * 2)
                return -((norm / (Math.PI * 2)) * parent.width * 2) % (parent.width * 2)
            }
            y: {
                let t = (moonBase.rotX + moonBase.camX) / (Math.PI * 0.5)
                t = Math.max(-1, Math.min(1, t))
                return -parent.height * 0.25 - t * parent.height * 0.25
            }
            source: "../../../assets/moon.jpg"
            fillMode: Image.Stretch; smooth: true; asynchronous: true
        }
        Image {
            width: parent.width * 2; height: parent.height * 2
            x: moonTexture.x + parent.width * 2
            y: moonTexture.y
            source: "../../../assets/moon.jpg"
            fillMode: Image.Stretch; smooth: true; asynchronous: true
        }
    }

    RadialGradient {
        anchors.fill: parent
        z: 1
        horizontalOffset: moonBase.sunValueX * (parent.width * 0.45)
        verticalOffset:  -moonBase.sunValueY * (parent.height * 0.45)
        horizontalRadius: parent.width * 0.72
        verticalRadius:   parent.height * 0.72
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.68; color: Qt.rgba(0, 0, 1/255, 0.55) }
            GradientStop { position: 0.82; color: Qt.rgba(0, 0, 0, 0.88) }
            GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.96) }
        }
    }

    RadialGradient {
        anchors.fill: parent
        z: 2
        horizontalOffset: moonBase.sunValueX * (parent.width * 0.25)
        verticalOffset: moonBase.sunValueY * (parent.height * 0.25)
        horizontalRadius: parent.width * 0.85
        verticalRadius: parent.height * 0.85
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.55; color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.15) }
            GradientStop { position: 0.88; color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.5) }
            GradientStop { position: 1.0; color: "#020407" }
        }
    }

    RadialGradient {
        anchors.fill: parent
        z: 3
        horizontalOffset: moonBase.sunValueX * (parent.width * 0.2)
        verticalOffset: moonBase.sunValueY * (parent.height * 0.2)
        horizontalRadius: parent.width * 0.5
        verticalRadius: parent.height * 0.5
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(theme.yellow.r, theme.yellow.g, theme.yellow.b, 0.3) }
            GradientStop { position: 0.3; color: Qt.rgba(theme.peach.r, theme.peach.g, theme.peach.b, 0.05) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    RadialGradient {
        anchors.fill: parent
        z: 4
        horizontalRadius: parent.width / 2
        verticalRadius: parent.height / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.85; color: "transparent" }
            GradientStop { position: 0.98; color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.25) }
            GradientStop { position: 1.0;  color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.60) }
        }
    }
}
