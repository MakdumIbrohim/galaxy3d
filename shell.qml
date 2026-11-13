import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // Twinkling Stars in deep space
    Stars {}

    // Background Earth & 3D Moon
    Moon {
        id: moonBg
        isSearchMode: launcherWindow.visible
        rotX: launcherWindow.visible ? launcherContent.rotX : -0.2
        rotY: launcherWindow.visible ? launcherContent.rotY : 0.0
    }

    // Sci-Fi Glass Top Bar (Media player, Workspaces, Clock, Status)
    TopBar {}

    // Desktop Notifications
    Notifications {}

    // 3D Orbital App Launcher Overlay
    PanelWindow {
        id: launcherWindow
        visible: false

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: launcherWindow.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "galaxy3d-launcher"
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        Item {
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: launcherWindow.visible = false
            }

            Applauncher {
                id: launcherContent
                anchors.fill: parent
            }
        }
    }

    // IPC handler for Super / Super+A
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            launcherWindow.visible = !launcherWindow.visible;
            if (launcherWindow.visible) {
                launcherContent.searchInput.forceActiveFocus();
            }
        }
        function open(): void {
            launcherWindow.visible = true;
            launcherContent.searchInput.forceActiveFocus();
        }
        function close(): void { launcherWindow.visible = false; }
    }
}
