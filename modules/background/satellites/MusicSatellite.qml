import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../../../theme"

Item {
    id: musicSatellite

    property real orbitDistance: 1.18
    property real angle: 0
    property var proj: ({ x: 0, y: 0, z: 0 })
    property real sphereRadius: 260
    property real satelliteZoom: 1.0
    property bool isSearchMode: false
    property bool pressed: false
    property real centerWidth: parent ? parent.width : 520
    property real centerHeight: parent ? parent.height : 520
    property real independentCometAngle: 0

    readonly property MprisPlayer activePlayer: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    readonly property bool isMusicActive: activePlayer !== null

    MatugenColors { id: theme }

    x: (centerWidth / 2) + (proj.x * sphereRadius) - width / 2
    y: (centerHeight / 2) + (proj.y * sphereRadius) - height / 2
    z: Math.round(proj.z * 1000)

    opacity: !isSearchMode && isMusicActive ? 1.0 : 0.0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 300 } }

    property real baselineDepthScale: 0.65 + (Math.max(0.0, proj.z) * 0.25)
    property real centerFocusFactor:  (proj.z > 0) ? Math.max(0.0, 1.0 - (Math.abs(proj.x) * 1.6)) : 0.0
    scale: (baselineDepthScale + (centerFocusFactor * 0.12)) * 1.45 * satelliteZoom
    Behavior on scale {
        enabled: !musicSatellite.pressed
        NumberAnimation { duration: 500; easing.type: Easing.OutBack }
    }

    width:  240
    height: 70

    property real xNorm: proj.x / orbitDistance
    property real yNorm: proj.y / orbitDistance

    transform: [
        Rotation {
            axis { x: 1; y: 0; z: 0 }
            angle: -musicSatellite.yNorm * 50
            origin.x: musicSatellite.width / 2
            origin.y: musicSatellite.height / 2
        },
        Rotation {
            axis { x: 0; y: 1; z: 0 }
            angle: musicSatellite.xNorm * 60
            origin.x: musicSatellite.width / 2
            origin.y: musicSatellite.height / 2
        }
    ]

    Rectangle {
        id: musicExhaust
        width: 60; height: 25
        anchors.horizontalCenter: musicChassis.horizontalCenter
        anchors.top: musicChassis.bottom
        anchors.topMargin: -2
        z: -1
        opacity: 0.25 + Math.sin(musicSatellite.independentCometAngle * 4 + 4) * 0.05
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.35) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        width: 180; height: 56; anchors.centerIn: parent; radius: 14
        color: theme.crust; border.color: Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.2); border.width: 1.2
        transform: Translate { x: -musicSatellite.xNorm * 8; y: musicSatellite.yNorm * 8 }
    }
    Rectangle {
        width: 180; height: 56; anchors.centerIn: parent; radius: 14
        color: theme.mantle; border.color: Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.35); border.width: 1.2
        transform: Translate { x: -musicSatellite.xNorm * 4; y: musicSatellite.yNorm * 4 }
    }
    Rectangle {
        id: musicChassis
        anchors.centerIn: parent
        width: 180; height: 56
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.94)
        border.color: musicSatellite.centerFocusFactor > 0
            ? Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.5)
            : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.5)
        border.width: 1.2; radius: 14
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
            anchors.centerIn: parent
            spacing: 10

            Rectangle {
                width: 36; height: 36; radius: 8; color: theme.surface1
                border.width: 1; border.color: theme.mauve
                clip: true
                Image {
                    anchors.fill: parent
                    source: musicSatellite.activePlayer && musicSatellite.activePlayer.trackArtUrl ? musicSatellite.activePlayer.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 16
                    color: theme.green
                    visible: !musicSatellite.activePlayer || !musicSatellite.activePlayer.trackArtUrl
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: musicSatellite.activePlayer ? (musicSatellite.activePlayer.trackTitle || "Unknown Track") : "No Media"
                    font.family: "JetBrains Mono"; font.weight: Font.Black
                    font.pixelSize: 12; color: theme.text
                    width: 110; elide: Text.ElideRight
                }
                Text {
                    text: musicSatellite.activePlayer ? (musicSatellite.activePlayer.trackArtist || (musicSatellite.activePlayer.playbackState === MprisPlaybackState.Playing ? "Playing" : "Paused")) : "Stopped"
                    font.family: "JetBrains Mono"; font.weight: Font.Bold
                    font.pixelSize: 10; color: theme.subtext0
                    width: 110; elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: if (musicSatellite.activePlayer) musicSatellite.activePlayer.togglePlaying()
        }
    }

    Rectangle {
        id: mLeftWing
        anchors.right: musicChassis.left; anchors.rightMargin: 4
        anchors.verticalCenter: musicChassis.verticalCenter
        width: 24; height: 38; color: theme.mantle
        border.color: Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.35)
        border.width: 1; radius: 2
        Grid { anchors.fill: parent; anchors.margins: 2; columns: 2; rows: 3; spacing: 1
            Repeater { model: 6
                Rectangle {
                    width: (mLeftWing.width - 5) / 2; height: (mLeftWing.height - 6) / 3
                    color: Qt.rgba(theme.green.r, theme.green.g, theme.green.b, index % 2 === 0 ? 0.25 : 0.1)
                }
            }
        }
    }

    Rectangle {
        id: mRightWing
        anchors.left: musicChassis.right; anchors.leftMargin: 4
        anchors.verticalCenter: musicChassis.verticalCenter
        width: 24; height: 38; color: theme.mantle
        border.color: Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.35)
        border.width: 1; radius: 2
        Grid { anchors.fill: parent; anchors.margins: 2; columns: 2; rows: 3; spacing: 1
            Repeater { model: 6
                Rectangle {
                    width: (mRightWing.width - 5) / 2; height: (mRightWing.height - 6) / 3
                    color: Qt.rgba(theme.green.r, theme.green.g, theme.green.b, index % 2 === 0 ? 0.25 : 0.1)
                }
            }
        }
    }
}
