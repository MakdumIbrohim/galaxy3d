import QtQuick
import Quickshell
import "../../../theme"
import "../../../services"

Item {
    id: sysInfoSatellite

    property real orbitDistance: 1.60
    property real angle: 0
    property var proj: ({ x: 0, y: 0, z: 0 })
    property real sphereRadius: 260
    property real satelliteZoom: 1.0
    property bool isSearchMode: false
    property bool pressed: false
    property real centerWidth: parent ? parent.width : 520
    property real centerHeight: parent ? parent.height : 520
    property real independentCometAngle: 0

    property string kbLayout: "us"
    property string volIcon: "󰕾"
    property string volPercent: "0%"
    property bool isSoundActive: false
    property bool showEthernet: false
    property string ethStatus: "Ethernet"
    property bool isWifiOn: false
    property string wifiIcon: "󰤮"
    property string wifiSsid: ""
    property bool isBtOn: false
    property string btIcon: "󰂲"
    property string btDevice: ""
    property bool isDesktop: false
    property color batColor: theme.green
    property string batIcon: "󰁹"
    property string batPercent: "100%"

    MatugenColors { id: theme }
    Caching { id: paths }

    x: (centerWidth / 2) + (proj.x * sphereRadius) - width / 2
    y: (centerHeight / 2) + (proj.y * sphereRadius) - height / 2
    z: Math.round(proj.z * 1000)

    opacity: isSearchMode ? 0.0 : 1.0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 300 } }

    property real baselineDepthScale: 0.72 + (Math.max(0.0, proj.z) * 0.25)
    property real centerFocusFactor:  (proj.z > 0) ? Math.max(0.0, 1.0 - (Math.abs(proj.x) * 1.6)) : 0.0
    scale: (baselineDepthScale + (centerFocusFactor * 0.12)) * 1.45 * satelliteZoom
    Behavior on scale {
        enabled: !sysInfoSatellite.pressed
        NumberAnimation { duration: 500; easing.type: Easing.OutBack }
    }

    width:  340
    height: 140

    property real xNorm: proj.x / orbitDistance
    property real yNorm: proj.y / orbitDistance

    transform: [
        Rotation {
            axis { x: 1; y: 0; z: 0 }
            angle: -sysInfoSatellite.yNorm * 55
            origin.x: sysInfoSatellite.width / 2
            origin.y: sysInfoSatellite.height / 2
        },
        Rotation {
            axis { x: 0; y: 1; z: 0 }
            angle: sysInfoSatellite.xNorm * 60
            origin.x: sysInfoSatellite.width / 2
            origin.y: sysInfoSatellite.height / 2
        }
    ]

    Item {
        anchors.centerIn: parent
        width: parent.width
        height: 90

        Rectangle {
            id: sysExhaust
            width: 80; height: 30
            anchors.horizontalCenter: sysCoreChassis.horizontalCenter
            anchors.top: sysCoreChassis.bottom
            anchors.topMargin: -2
            z: -1
            opacity: 0.25 + Math.sin(sysInfoSatellite.independentCometAngle * 4 + 3) * 0.05
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.35) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            width: 55; height: 50; anchors.right: sysCoreChassis.left; anchors.rightMargin: 6; anchors.verticalCenter: sysCoreChassis.verticalCenter
            color: theme.crust; border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.15); border.width: 1; radius: 4
            transform: Translate { x: -sysInfoSatellite.xNorm * 10; y: sysInfoSatellite.yNorm * 10 }
        }
        Rectangle {
            width: 55; height: 50; anchors.right: sysCoreChassis.left; anchors.rightMargin: 6; anchors.verticalCenter: sysCoreChassis.verticalCenter
            color: theme.mantle; border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.25); border.width: 1; radius: 4
            transform: Translate { x: -sysInfoSatellite.xNorm * 5; y: sysInfoSatellite.yNorm * 5 }
        }
        Rectangle {
            id: sysLPanel
            width: 55; height: 50
            anchors.right: sysCoreChassis.left
            anchors.rightMargin: 6
            anchors.verticalCenter: sysCoreChassis.verticalCenter
            color: theme.mantle
            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
            border.width: 1; radius: 4
            Grid {
                anchors.fill: parent; anchors.margins: 4; columns: 3; rows: 3; spacing: 2
                Repeater { model: 9
                    Rectangle {
                        width:  (sysLPanel.width  - 8 - 4) / 3
                        height: (sysLPanel.height - 8 - 4) / 3
                        color: Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, index % 2 === 0 ? 0.16 : 0.06)
                        radius: 1
                    }
                }
            }
        }

        Rectangle {
            width: 200; height: 90; anchors.centerIn: parent; radius: 14
            color: theme.crust; border.color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.2); border.width: 1.2
            transform: Translate { x: -sysInfoSatellite.xNorm * 10; y: sysInfoSatellite.yNorm * 10 }
        }
        Rectangle {
            width: 200; height: 90; anchors.centerIn: parent; radius: 14
            color: theme.mantle; border.color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.35); border.width: 1.2
            transform: Translate { x: -sysInfoSatellite.xNorm * 5; y: sysInfoSatellite.yNorm * 5 }
        }
        Rectangle {
            id: sysCoreChassis
            width: 200; height: 90
            anchors.centerIn: parent
            color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.94)
            border.color: sysInfoSatellite.centerFocusFactor > 0
                ? Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.5)
                : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.5)
            border.width: 1.2; radius: 14
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Rectangle {
                width: 4; height: 4; radius: 2; color: theme.teal
                anchors.top: parent.top; anchors.topMargin: 5
                anchors.right: parent.right; anchors.rightMargin: 7
                SequentialAnimation on opacity { loops: Animation.Infinite; running: true
                    NumberAnimation { from: 1; to: 0.1; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.1; to: 1; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            Grid {
                id: sysPillGrid
                anchors.centerIn: parent
                columns: 2; rows: 3; spacing: 4

                Rectangle {
                    id: kbPill
                    width: 80; height: 20; radius: 6
                    color: kbPillMouse.containsMouse
                        ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.8)
                        : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.5)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    scale: kbPillMouse.pressed ? 0.92 : (kbPillMouse.containsMouse ? 1.06 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                    Row {
                        anchors.centerIn: parent; spacing: 4
                        Text { text: "󰌌"; font.family: "Iosevka Nerd Font"; font.pixelSize: 11; color: theme.overlay0; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: sysInfoSatellite.kbLayout; font.family: "JetBrains Mono"; font.pixelSize: 10; font.weight: Font.Black; color: theme.text; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: kbPillMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "main", "next"]) }
                }

                Rectangle {
                    id: volPill
                    width: 80; height: 20; radius: 6
                    color: volPillMouse.containsMouse
                        ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.8)
                        : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.5)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        anchors.fill: parent; radius: parent.radius
                        opacity: sysInfoSatellite.isSoundActive ? 0.85 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        gradient: Gradient { orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: theme.peach }
                            GradientStop { position: 1.0; color: Qt.lighter(theme.peach, 1.3) }
                        }
                    }
                    scale: volPillMouse.pressed ? 0.92 : (volPillMouse.containsMouse ? 1.06 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                    Row {
                        anchors.centerIn: parent; spacing: 4
                        Text { text: sysInfoSatellite.volIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 11; color: sysInfoSatellite.isSoundActive ? theme.base : theme.subtext0; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: sysInfoSatellite.volPercent; font.family: "JetBrains Mono"; font.pixelSize: 10; font.weight: Font.Black; color: sysInfoSatellite.isSoundActive ? theme.base : theme.text; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: volPillMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash", "-c", paths.serpantinumDir + "/scripts/qs_manager.sh toggle volume"]) }
                }

                Rectangle {
                    id: wifiSatPill
                    width: 80; height: 20; radius: 6
                    color: wifiSatPillMouse.containsMouse
                        ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.8)
                        : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.5)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        anchors.fill: parent; radius: parent.radius
                        opacity: sysInfoSatellite.showEthernet ? (sysInfoSatellite.ethStatus === "Connected" ? 1.0 : 0.0) : (sysInfoSatellite.isWifiOn ? 1.0 : 0.0)
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        gradient: Gradient { orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: theme.blue }
                            GradientStop { position: 1.0; color: Qt.lighter(theme.blue, 1.3) }
                        }
                    }
                    scale: wifiSatPillMouse.pressed ? 0.92 : (wifiSatPillMouse.containsMouse ? 1.06 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                    Row {
                        anchors.centerIn: parent; spacing: 4
                        Text {
                            text: sysInfoSatellite.showEthernet ? "󰈀" : sysInfoSatellite.wifiIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 11
                            color: sysInfoSatellite.showEthernet ? (sysInfoSatellite.ethStatus === "Connected" ? theme.base : theme.subtext0) : (sysInfoSatellite.isWifiOn ? theme.base : theme.subtext0)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: sysInfoSatellite.showEthernet ? sysInfoSatellite.ethStatus : (sysInfoSatellite.isWifiOn ? (sysInfoSatellite.wifiSsid !== "" ? sysInfoSatellite.wifiSsid : "On") : "Off")
                            font.family: "JetBrains Mono"; font.pixelSize: 10; font.weight: Font.Black
                            color: sysInfoSatellite.showEthernet ? (sysInfoSatellite.ethStatus === "Connected" ? theme.base : theme.text) : (sysInfoSatellite.isWifiOn ? theme.base : theme.text)
                            elide: Text.ElideRight; width: 52; anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea { id: wifiSatPillMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash", "-c", paths.serpantinumDir + "/scripts/qs_manager.sh toggle network wifi"]) }
                }

                Rectangle {
                    id: btSatPill
                    width: 80; height: 20; radius: 6
                    visible: !sysInfoSatellite.isDesktop
                    color: btSatPillMouse.containsMouse
                        ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.8)
                        : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.5)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        anchors.fill: parent; radius: parent.radius
                        opacity: sysInfoSatellite.isBtOn ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        gradient: Gradient { orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: theme.mauve }
                            GradientStop { position: 1.0; color: Qt.lighter(theme.mauve, 1.3) }
                        }
                    }
                    scale: btSatPillMouse.pressed ? 0.92 : (btSatPillMouse.containsMouse ? 1.06 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                    Row {
                        anchors.centerIn: parent; spacing: 4
                        Text { text: sysInfoSatellite.btIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 11; color: sysInfoSatellite.isBtOn ? theme.base : theme.subtext0; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: sysInfoSatellite.isBtOn ? (sysInfoSatellite.btDevice !== "" ? sysInfoSatellite.btDevice : "On") : "Off"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.weight: Font.Black; color: sysInfoSatellite.isBtOn ? theme.base : theme.text; elide: Text.ElideRight; width: 52; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: btSatPillMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash", "-c", paths.serpantinumDir + "/scripts/qs_manager.sh toggle network bt"]) }
                }

                Rectangle {
                    id: batSatPill
                    width: 80; height: 20; radius: 6
                    color: batSatPillMouse.containsMouse
                        ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.8)
                        : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.5)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Rectangle {
                        anchors.fill: parent; radius: parent.radius; opacity: 1.0
                        gradient: Gradient { orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: sysInfoSatellite.isDesktop ? theme.red : sysInfoSatellite.batColor; Behavior on color { ColorAnimation { duration: 300 } } }
                            GradientStop { position: 1.0; color: sysInfoSatellite.isDesktop ? Qt.lighter(theme.red, 1.3) : Qt.lighter(sysInfoSatellite.batColor, 1.3); Behavior on color { ColorAnimation { duration: 300 } } }
                        }
                    }
                    scale: batSatPillMouse.pressed ? 0.92 : (batSatPillMouse.containsMouse ? 1.06 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                    Row {
                        anchors.centerIn: parent; spacing: 4
                        Text { text: sysInfoSatellite.isDesktop ? "" : sysInfoSatellite.batIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: sysInfoSatellite.isDesktop ? 13 : 11; color: theme.base; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: sysInfoSatellite.batPercent; font.family: "JetBrains Mono"; font.pixelSize: 10; font.weight: Font.Black; color: theme.base; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: batSatPillMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash", "-c", paths.serpantinumDir + "/scripts/qs_manager.sh toggle battery"]) }
                }

                Rectangle {
                    id: notifSatPill
                    width: 80; height: 20; radius: 6
                    color: notifSatPillMouse.containsMouse
                        ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.8)
                        : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.5)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    scale: notifSatPillMouse.pressed ? 0.92 : (notifSatPillMouse.containsMouse ? 1.06 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                    Row {
                        anchors.centerIn: parent; spacing: 4
                        Text { text: "󰂚"; font.family: "Iosevka Nerd Font"; font.pixelSize: 11; color: theme.overlay0; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Notifs"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.weight: Font.Black; color: theme.text; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: notifSatPillMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash", "-c", paths.serpantinumDir + "/scripts/qs_manager.sh toggle notifications"]) }
                }
            }
        }

        Rectangle { width: 55; height: 50; anchors.left: sysCoreChassis.right; anchors.leftMargin: 6; anchors.verticalCenter: sysCoreChassis.verticalCenter
            color: theme.crust; border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.15); border.width: 1; radius: 4
            transform: Translate { x: -sysInfoSatellite.xNorm * 10; y: sysInfoSatellite.yNorm * 10 }
        }
        Rectangle {
            width: 55; height: 50; anchors.left: sysCoreChassis.right; anchors.leftMargin: 6; anchors.verticalCenter: sysCoreChassis.verticalCenter
            color: theme.mantle; border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.25); border.width: 1; radius: 4
            transform: Translate { x: -sysInfoSatellite.xNorm * 5; y: sysInfoSatellite.yNorm * 5 }
        }
        Rectangle {
            id: sysRPanel
            width: 55; height: 50
            anchors.left: sysCoreChassis.right
            anchors.leftMargin: 6
            anchors.verticalCenter: sysCoreChassis.verticalCenter
            color: theme.mantle
            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
            border.width: 1; radius: 4
            Grid {
                anchors.fill: parent; anchors.margins: 4; columns: 3; rows: 3; spacing: 2
                Repeater { model: 9
                    Rectangle {
                        width:  (sysRPanel.width  - 8 - 4) / 3
                        height: (sysRPanel.height - 8 - 4) / 3
                        color: Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, index % 2 === 0 ? 0.16 : 0.06)
                        radius: 1
                    }
                }
            }
        }
    }
}
