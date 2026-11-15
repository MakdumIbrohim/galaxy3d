import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: root

    property string searchQuery: ""

    MatugenColors { id: colors }
    Scaler { id: scaler; currentWidth: Screen.width }

    function s(val) {
        let res = scaler.s(val);
        return res > 0 ? res : val;
    }

    readonly property real _sat_hullW:     s(270)
    readonly property real _sat_hullH:     s(185)
    readonly property real _sat_panelW:    s(80)
    readonly property real _sat_panelH:    s(64)
    readonly property real _sat_strutW:    s(12)
    readonly property real _sat_strutH:    s(5)
    readonly property real _sat_antennaH:  s(20)
    readonly property real _sat_thrusterH: s(14)
    readonly property real _sat_radius12:  s(12)
    readonly property real _sat_radius8:   s(8)
    readonly property real _sat_radius4:   s(4)
    readonly property real _sat_antBall:   s(8)
    readonly property real _sat_antStick:  s(3)
    readonly property real _sat_antOffX:   s(18)
    readonly property real _sat_screenM:   s(10)
    readonly property real _sat_innerM:    s(12)
    readonly property real _sat_iconSz:    s(44)
    readonly property real _sat_fontSize:  s(12)
    readonly property real _sat_thrBase:   s(20)
    readonly property real _sat_spacing:   s(6)
    readonly property real _s2:            s(2)

    readonly property real satW: _sat_panelW + _sat_strutW + _sat_hullW + _sat_strutW + _sat_panelW
    readonly property real satH: _sat_hullH + _sat_antennaH + _sat_thrusterH + s(11)

    width: satW
    height: satH

    // Subtle zero-g drift / tumble animation for space debris
    SequentialAnimation on rotation {
        loops: Animation.Infinite
        running: root.visible
        NumberAnimation { from: -7; to: -4; duration: 2800; easing.type: Easing.InOutSine }
        NumberAnimation { from: -4; to: -7; duration: 2800; easing.type: Easing.InOutSine }
    }

    SequentialAnimation on y {
        loops: Animation.Infinite
        running: root.visible
        NumberAnimation { from: 0; to: -4; duration: 2400; easing.type: Easing.InOutSine }
        NumberAnimation { from: -4; to: 0; duration: 2400; easing.type: Easing.InOutSine }
    }

    // Broken / Snapped Left Solar Panel
    Rectangle {
        id: lPanel
        width: root._sat_panelW
        height: root._sat_panelH
        anchors.right: lStrut.left
        anchors.verticalCenter: hull.verticalCenter
        anchors.verticalCenterOffset: root.s(14)
        transformOrigin: Item.Right
        rotation: -24
        color: colors.mantle
        border.color: Qt.alpha(colors.red, 0.45)
        border.width: 1
        radius: root._sat_radius4

        Grid {
            anchors.fill: parent
            anchors.margins: root._sat_screenM * 0.5
            columns: 4; rows: 4
            spacing: root._s2
            Repeater {
                model: 16
                Rectangle {
                    width: (lPanel.width - root._sat_screenM - 3 * root._s2) / 4
                    height: (lPanel.height - root._sat_screenM - 3 * root._s2) / 4
                    // Damaged / shattered cells
                    color: index % 5 === 0
                        ? Qt.alpha(colors.red, 0.35)
                        : (index % 3 === 0 ? Qt.alpha(colors.surface0, 0.3) : Qt.alpha(colors.peach, 0.08))
                    radius: 1
                }
            }
        }
    }

    // Bent Left Strut
    Rectangle {
        id: lStrut
        width: root._sat_strutW
        height: root._sat_strutH
        anchors.right: hull.left
        anchors.verticalCenter: hull.verticalCenter
        transformOrigin: Item.Right
        rotation: -18
        color: Qt.alpha(colors.red, 0.5)

        // Electrical Spark Particles from Fractured Strut
        Item {
            anchors.centerIn: parent
            width: 1; height: 1

            Repeater {
                model: [
                    { delay: 0,    dur: 1100, dx: -20, dy: -14, col: colors.peach },
                    { delay: 350,  dur: 950,  dx: -14, dy: 16,  col: colors.red },
                    { delay: 700,  dur: 1250, dx: -26, dy: 6,   col: "#ffffff" },
                    { delay: 1050, dur: 850,  dx: -18, dy: -22, col: colors.yellow }
                ]

                delegate: Rectangle {
                    id: sparkDot
                    width: root.s(2.5)
                    height: width
                    radius: width / 2
                    color: modelData.col

                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: root.visible

                        PauseAnimation { duration: modelData.delay }

                        ParallelAnimation {
                            NumberAnimation {
                                target: sparkDot
                                property: "x"
                                from: 0
                                to: modelData.dx
                                duration: modelData.dur
                                easing.type: Easing.OutQuad
                            }
                            NumberAnimation {
                                target: sparkDot
                                property: "y"
                                from: 0
                                to: modelData.dy
                                duration: modelData.dur
                                easing.type: Easing.OutQuad
                            }
                            SequentialAnimation {
                                NumberAnimation { target: sparkDot; property: "opacity"; from: 0.0; to: 1.0; duration: modelData.dur * 0.2 }
                                NumberAnimation { target: sparkDot; property: "opacity"; from: 1.0; to: 0.0; duration: modelData.dur * 0.8 }
                            }
                            NumberAnimation {
                                target: sparkDot
                                property: "scale"
                                from: 1.6
                                to: 0.2
                                duration: modelData.dur
                            }
                        }

                        PauseAnimation { duration: 600 }
                    }
                }
            }
        }
    }

    // Main Satellite Hull (Distressed / Damaged Frame)
    Rectangle {
        id: hull
        width: root._sat_hullW
        height: root._sat_hullH
        anchors.centerIn: parent
        anchors.verticalCenterOffset: (root._sat_antennaH - root._sat_thrusterH) * 0.5
        color: colors.base
        border.color: Qt.alpha(colors.red, 0.55)
        border.width: 1.5
        radius: root._sat_radius12

        // Warning Hazard Accent Line across top of hull
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - root.s(40)
            height: 2
            radius: 1
            color: Qt.alpha(colors.red, 0.6)
        }

        // Bent / Broken Antenna
        Rectangle {
            width: root._sat_antStick
            height: root._sat_antennaH * 0.9
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -root._sat_antOffX
            anchors.bottom: parent.top
            transformOrigin: Item.Bottom
            rotation: 26
            color: Qt.alpha(colors.red, 0.7)
            radius: 1

            // Blinking Warning Beacon on tip
            Rectangle {
                id: antennaBall
                width: root._sat_antBall
                height: root._sat_antBall
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                color: colors.red

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: root.visible
                    NumberAnimation { from: 1.0; to: 0.2; duration: 600 }
                    NumberAnimation { from: 0.2; to: 1.0; duration: 600 }
                }

                // Antenna Spark Discharge
                Item {
                    anchors.centerIn: parent
                    width: 1; height: 1
                    Repeater {
                        model: [
                            { delay: 200, dur: 700, dx: 14, dy: -12, col: colors.red },
                            { delay: 650, dur: 800, dx: -10, dy: -16, col: "#ffffff" }
                        ]
                        delegate: Rectangle {
                            id: antSpark
                            width: root.s(2)
                            height: width
                            radius: width / 2
                            color: modelData.col
                            SequentialAnimation {
                                loops: Animation.Infinite
                                running: root.visible
                                PauseAnimation { duration: modelData.delay }
                                ParallelAnimation {
                                    NumberAnimation { target: antSpark; property: "x"; from: 0; to: modelData.dx; duration: modelData.dur; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: antSpark; property: "y"; from: 0; to: modelData.dy; duration: modelData.dur; easing.type: Easing.OutQuad }
                                    SequentialAnimation {
                                        NumberAnimation { target: antSpark; property: "opacity"; from: 0.0; to: 1.0; duration: modelData.dur * 0.2 }
                                        NumberAnimation { target: antSpark; property: "opacity"; from: 1.0; to: 0.0; duration: modelData.dur * 0.8 }
                                    }
                                }
                                PauseAnimation { duration: 900 }
                            }
                        }
                    }
                }
            }
        }

        // Inner Glitched Screen Area
        Rectangle {
            id: glitchScreen
            anchors.fill: parent
            anchors.margins: root._sat_screenM
            color: colors.mantle
            radius: root._sat_radius8
            border.color: Qt.alpha(colors.red, 0.35)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root._sat_innerM
                spacing: root._sat_spacing

                // Malfunctioning / Lost Signal Radar Icon
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: root._sat_iconSz
                    height: root._sat_iconSz
                    radius: width / 2
                    color: Qt.alpha(colors.surface0, 0.6)
                    border.color: Qt.alpha(colors.red, 0.45)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰮐"
                        font.family: "JetBrains Mono Nerd Font, Symbols Nerd Font, monospace"
                        font.pixelSize: root.s(22)
                        color: colors.red
                    }
                }

                // Application Not Found Title
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    text: "Application Not Found"
                    font.family: "JetBrains Mono"
                    font.pixelSize: root._sat_fontSize
                    font.weight: Font.Bold
                    color: colors.text
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                // Query Text Feedback
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    text: "No results for \"" + root.searchQuery + "\""
                    font.family: "JetBrains Mono"
                    font.pixelSize: root.s(10)
                    color: colors.subtext0
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                }

                // Status Badge
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: statusText.implicitWidth + root.s(14)
                    height: root.s(18)
                    radius: height / 2
                    color: Qt.alpha(colors.red, 0.15)
                    border.color: Qt.alpha(colors.red, 0.35)
                    border.width: 1

                    Text {
                        id: statusText
                        anchors.centerIn: parent
                        text: "SIGNAL LOST • OFFLINE"
                        font.family: "JetBrains Mono"
                        font.pixelSize: root.s(8)
                        font.bold: true
                        color: colors.red
                    }
                }
            }
        }

        // Disabled Thruster (Cold / Sparks)
        Rectangle {
            width: root._sat_thrBase
            height: root._sat_thrusterH * 0.5
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            color: colors.surface1
            radius: 2
            transformOrigin: Item.Top
            rotation: -8

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                width: parent.width * 0.6
                height: root._sat_thrusterH
                radius: width / 2
                color: Qt.alpha(colors.red, 0.2)
            }
        }
    }

    // Fractured Right Solar Panel (Askew / Jammed)
    Rectangle {
        id: rPanel
        width: root._sat_panelW
        height: root._sat_panelH
        anchors.left: rStrut.right
        anchors.verticalCenter: hull.verticalCenter
        anchors.verticalCenterOffset: -root.s(10)
        transformOrigin: Item.Left
        rotation: 20
        color: colors.mantle
        border.color: Qt.alpha(colors.peach, 0.45)
        border.width: 1
        radius: root._sat_radius4

        Grid {
            anchors.fill: parent
            anchors.margins: root._sat_screenM * 0.5
            columns: 4; rows: 4
            spacing: root._s2
            Repeater {
                model: 16
                Rectangle {
                    width: (rPanel.width - root._sat_screenM - 3 * root._s2) / 4
                    height: (rPanel.height - root._sat_screenM - 3 * root._s2) / 4
                    color: index > 9
                        ? Qt.alpha(colors.surface0, 0.25)
                        : (index % 2 === 0 ? Qt.alpha(colors.peach, 0.25) : Qt.alpha(colors.red, 0.12))
                    radius: 1
                }
            }
        }
    }

    // Bent Right Strut
    Rectangle {
        id: rStrut
        width: root._sat_strutW
        height: root._sat_strutH
        anchors.left: hull.right
        anchors.verticalCenter: hull.verticalCenter
        transformOrigin: Item.Left
        rotation: 12
        color: Qt.alpha(colors.peach, 0.5)
    }
}
