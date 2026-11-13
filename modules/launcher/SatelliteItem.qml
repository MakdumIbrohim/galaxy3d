import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: root

    property string appName: ""
    property string appIcon: ""

    MatugenColors { id: colors }
    Scaler { id: scaler; currentWidth: Screen.width }

    function s(val) {
        let res = scaler.s(val);
        return res > 0 ? res : val;
    }

    readonly property real _sat_hullW:     s(216)
    readonly property real _sat_hullH:     s(148)
    readonly property real _sat_panelW:    s(64)
    readonly property real _sat_panelH:    s(51)
    readonly property real _sat_strutW:    s(10)
    readonly property real _sat_strutH:    s(4)
    readonly property real _sat_antennaH:  s(16)
    readonly property real _sat_thrusterH: s(11)
    readonly property real _sat_radius12:  s(10)
    readonly property real _sat_radius8:   s(7)
    readonly property real _sat_radius4:   s(3)
    readonly property real _sat_antBall:   s(6)
    readonly property real _sat_antStick:  s(2)
    readonly property real _sat_antOffX:   s(14)
    readonly property real _sat_screenM:   s(8)
    readonly property real _sat_innerM:    s(10)
    readonly property real _sat_iconSz:    s(40)
    readonly property real _sat_fontSize:  s(10)
    readonly property real _sat_thrBase:   s(16)
    readonly property real _sat_spacing:   s(5)
    readonly property real _s2:            s(2)

    readonly property real satW: _sat_panelW + _sat_strutW + _sat_hullW + _sat_strutW + _sat_panelW
    readonly property real satH: _sat_hullH + _sat_antennaH + _sat_thrusterH + s(11)

    width: satW
    height: satH

    Rectangle {
        id: lPanel
        width: root._sat_panelW
        height: root._sat_panelH
        anchors.right: lStrut.left
        anchors.verticalCenter: hull.verticalCenter
        color: colors.mantle
        border.color: Qt.alpha(colors.surface2, 0.4)
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
                    color: Qt.alpha(colors.blue, index % 3 === 0 ? 0.15 : 0.05)
                    radius: 1
                }
            }
        }
    }

    Rectangle {
        id: lStrut
        width: root._sat_strutW
        height: root._sat_strutH
        anchors.right: hull.left
        anchors.verticalCenter: hull.verticalCenter
        color: Qt.alpha(colors.surface2, 0.5)
    }

    Rectangle {
        id: hull
        width: root._sat_hullW
        height: root._sat_hullH
        anchors.centerIn: parent
        anchors.verticalCenterOffset: (root._sat_antennaH - root._sat_thrusterH) * 0.5
        color: colors.base
        border.color: Qt.alpha(colors.surface1, 0.6)
        border.width: 1.5
        radius: root._sat_radius12

        Rectangle {
            width: root._sat_antStick
            height: root._sat_antennaH
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -root._sat_antOffX
            anchors.bottom: parent.top
            color: Qt.alpha(colors.surface2, 0.7)
            radius: 1
            Rectangle {
                width: root._sat_antBall
                height: root._sat_antBall
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                color: colors.blue
            }
        }

        Rectangle {
            id: notifScreen
            anchors.fill: parent
            anchors.margins: root._sat_screenM
            color: colors.mantle
            radius: root._sat_radius8
            border.color: Qt.alpha(colors.surface0, 0.5)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root._sat_innerM
                spacing: root._sat_spacing

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: root._sat_iconSz
                    Layout.preferredHeight: root._sat_iconSz
                    source: root.appIcon
                        ? (root.appIcon.startsWith("/")
                           ? "file://" + root.appIcon
                           : "image://icon/" + root.appIcon)
                        : "image://icon/application-x-executable"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    text: root.appName
                    font.family: "JetBrains Mono"
                    font.pixelSize: root._sat_fontSize
                    font.weight: Font.Bold
                    color: colors.text
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                }
            }
        }

        Rectangle {
            width: root._sat_thrBase
            height: root._sat_thrusterH * 0.5
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            color: colors.surface1
            radius: 2
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                width: parent.width * 0.6
                height: root._sat_thrusterH
                radius: width / 2
                color: Qt.alpha(colors.sapphire, 0.35)
            }
        }
    }

    Rectangle {
        id: rPanel
        width: root._sat_panelW
        height: root._sat_panelH
        anchors.left: rStrut.right
        anchors.verticalCenter: hull.verticalCenter
        color: colors.mantle
        border.color: Qt.alpha(colors.surface2, 0.4)
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
                    color: Qt.alpha(colors.blue, index % 3 === 0 ? 0.15 : 0.05)
                    radius: 1
                }
            }
        }
    }

    Rectangle {
        id: rStrut
        width: root._sat_strutW
        height: root._sat_strutH
        anchors.left: hull.right
        anchors.verticalCenter: hull.verticalCenter
        color: Qt.alpha(colors.surface2, 0.5)
    }
}
