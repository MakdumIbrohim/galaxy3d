import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "modules/background"
import "modules/bar"
import "modules/launcher"
import "modules/notifications"
import "modules/settings"
import "modules/osd"

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
    NotificationPopup {}

    // Audio & Brightness OSD Overlay
    OSD {}

    // Satellite Network Scanner Panel (Triggered by Right-Click)
    NetworkPanel {
        id: networkPanel
    }

    // Full Shell Settings Window
    SettingsWindow {
        id: settingsWin
    }

    // Cosmic Power & Session Menu
    PowerMenu {
        id: powerMenu
    }

    // Interactive Media Player Popup Flyout
    MediaPopup {
        id: mediaPopup
    }

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

    // IPC handler for Satellite / Wi-Fi Network Panel
    IpcHandler {
        target: "network"
        function toggle(): void { networkPanel.visible = !networkPanel.visible; }
        function open(): void { networkPanel.visible = true; }
        function close(): void { networkPanel.visible = false; }
    }

    // IPC handler for Shell Settings Window
    IpcHandler {
        target: "settings"
        function toggle(): void { settingsWin.visible = !settingsWin.visible; }
        function open(): void { settingsWin.visible = true; }
        function close(): void { settingsWin.visible = false; }
    }

    // IPC handler for Power Menu
    IpcHandler {
        target: "power"
        function toggle(): void { powerMenu.visible = !powerMenu.visible; }
        function open(): void { powerMenu.visible = true; }
        function close(): void { powerMenu.visible = false; }
    }

    // IPC handler for Media Popup Flyout
    IpcHandler {
        target: "media"
        function toggle(): void { mediaPopup.visible = !mediaPopup.visible; }
        function open(): void { mediaPopup.visible = true; }
        function close(): void { mediaPopup.visible = false; }
    }
}
