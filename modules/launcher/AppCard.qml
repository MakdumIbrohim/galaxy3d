import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: appNode

    property var proj: ({ x: 0, y: 0, z: 0 })
    property real sphereRadius: 265
    property real sphereZoom: 1.0
    property string searchQuery: ""
    property bool isSelected: false
    property string appName: ""
    property string appIcon: ""
    property string appExec: ""
    property string selectedAppName: ""
    property string selectedAppIcon: ""

    signal launchRequested(string name, string exec)

    MatugenColors { id: theme }
    Scaler { id: scaler; currentWidth: Screen.width }

    function s(val) {
        let res = scaler.s(val);
        return res > 0 ? res : val;
    }

    readonly property real _s2:   s(2)
    readonly property real _s3:   s(3)
    readonly property real _s4:   s(4)
    readonly property real _s5:   s(5)
    readonly property real _s11:  s(11)
    readonly property real _s12:  s(12)
    readonly property real _s55:  s(55)
    readonly property real _s74:  s(74)
    readonly property real _s104: s(104)

    property real zoomFactor: 1.0 + (appNode.sphereZoom - 1.0) * 0.45

    x: (parent.width  / 2) + (proj.x * appNode.sphereRadius * zoomFactor) - width  / 2
    y: (parent.height / 2) + (proj.y * appNode.sphereRadius * zoomFactor) - height / 2
    z: Math.round(proj.z * 1000)

    property bool isMatch: {
        if (appNode.searchQuery === "") return true;
        let n = appNode.appName.toLowerCase();
        let e = appNode.appExec.toLowerCase();
        return n.includes(appNode.searchQuery) || e.includes(appNode.searchQuery);
    }

    property real _hz: Math.max(0.0, Math.min(1.0, proj.z * 3.5))
    opacity: (appNode.searchQuery === "" ? (proj.z > -0.05 ? _hz : 0.0) : (isMatch ? 1.0 : 0.05))
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    visible: (proj.z > -0.05) && (appNode.searchQuery === "" ? (opacity > 0.02) : isMatch)

    property real _baseScale: isMatch && appNode.searchQuery !== "" ? 1.25 : (0.75 + (Math.max(0.0, proj.z) * 0.35))
    scale: isSelected ? 1.4 : (_baseScale * ((nodeMa.containsMouse && !isSelected) ? 1.15 : 1.0))
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    property real _xNorm: proj.x / (appNode.sphereRadius / s(310.5))
    property real _yNorm: proj.y / (appNode.sphereRadius / s(310.5))

    transform: [
        Rotation {
            axis { x: 1; y: 0; z: 0 }
            angle: appNode.isSelected ? 0 : -appNode._yNorm * 45
            origin.x: appNode.width  / 2
            origin.y: appNode.height / 2
        },
        Rotation {
            axis { x: 0; y: 1; z: 0 }
            angle: appNode.isSelected ? 0 : appNode._xNorm * 35
            origin.x: appNode.width  / 2
            origin.y: appNode.height / 2
        }
    ]

    width:  _s74
    height: _s104

    Rectangle {
        anchors.fill: parent
        radius: appNode._s12
        color: "transparent"
        border.color: nodeMa.containsMouse && !appNode.isSelected ? theme.surface2 : "transparent"
        border.width: appNode._s2
        Behavior on color { ColorAnimation { duration: 200 } }
        visible: !appNode.isSelected

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: appNode._s5
            spacing: appNode._s5

            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth:  appNode._s55
                Layout.preferredHeight: appNode._s55
                source: appNode.appIcon
                    ? (appNode.appIcon.startsWith("/") ? "file://" + appNode.appIcon : "image://icon/" + appNode.appIcon)
                    : "image://icon/application-x-executable"
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                cache: true
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: labelText.implicitHeight + appNode._s4
                radius: appNode._s4
                color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.60)

                Text {
                    id: labelText
                    anchors.fill: parent
                    anchors.leftMargin:  appNode._s3
                    anchors.rightMargin: appNode._s3
                    text: appNode.appName
                    font.family: "JetBrains Mono"
                    font.pixelSize: appNode._s11
                    font.weight: Font.DemiBold
                    color: theme.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }
        }
    }

    Loader {
        id: satLoader
        anchors.centerIn: parent
        active: appNode.isSelected
        opacity: appNode.isSelected ? 1.0 : 0.0
        scale:   appNode.isSelected ? 1.5 : 0.4

        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 450; easing.type: Easing.OutBack  } }

        sourceComponent: Component {
            SatelliteItem {
                appName: appNode.selectedAppName
                appIcon: appNode.selectedAppIcon
            }
        }
    }

    MouseArea {
        id: nodeMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: appNode.launchRequested(appNode.appName, appNode.appExec)
    }
}
