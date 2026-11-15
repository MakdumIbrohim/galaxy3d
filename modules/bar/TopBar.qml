import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: topBarWin

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: ShellBridge.topbarStyle === "tactical" ? 36 : 46
    WlrLayershell.namespace: "galaxy3d-topbar"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Auto
    color: "transparent"

    Loader {
        anchors.fill: parent
        source: {
            switch (ShellBridge.topbarStyle) {
                case "tactical": return "TacticalTopBar.qml";
                case "capsule":  return "CapsuleTopBar.qml";
                default:         return "CyberTopBar.qml";
            }
        }
    }
}
