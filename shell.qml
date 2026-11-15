import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "services"
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
        isSearchMode: launcherContent.isOpen
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
                onClicked: launcherContent.closeLauncher()
            }

            Applauncher {
                id: launcherContent
                anchors.fill: parent
                onCloseRequested: launcherWindow.visible = false
            }
        }
    }

    function toggleLauncher() {
        if (launcherWindow.visible && launcherContent.isOpen) {
            launcherContent.closeLauncher();
        } else {
            root.openLauncher();
        }
    }
    function openLauncher() {
        launcherWindow.visible = true;
        launcherContent.openLauncher();
    }
    function closeLauncher() {
        if (launcherWindow.visible) {
            launcherContent.closeLauncher();
        }
    }

    Connections {
        target: ShellBridge
        function onToggleLauncher() { root.toggleLauncher(); }
        function onOpenLauncher()   { root.openLauncher(); }
        function onCloseLauncher()  { root.closeLauncher(); }

        function onToggleNetwork()  { networkPanel.visible = !networkPanel.visible; }
        function onOpenNetwork()    { networkPanel.visible = true; }
        function onCloseNetwork()   { networkPanel.visible = false; }

        function onToggleSettings() { settingsWin.visible = !settingsWin.visible; }
        function onOpenSettings()   { settingsWin.visible = true; }
        function onCloseSettings()  { settingsWin.visible = false; }

        function onTogglePower()    { powerMenu.visible = !powerMenu.visible; }
        function onOpenPower()      { powerMenu.visible = true; }
        function onClosePower()     { powerMenu.visible = false; }

        function onToggleMedia()    { mediaPopup.visible = !mediaPopup.visible; }
        function onOpenMedia()      { mediaPopup.visible = true; }
        function onCloseMedia()     { mediaPopup.visible = false; }
    }

    // IPC handler for Super / Super+A
    IpcHandler {
        target: "launcher"
        function toggle() { root.toggleLauncher(); }
        function open() { root.openLauncher(); }
        function close() { root.closeLauncher(); }
    }

    // IPC handler for Satellite / Wi-Fi Network Panel
    IpcHandler {
        target: "network"
        function toggle() { networkPanel.visible = !networkPanel.visible; }
        function open() { networkPanel.visible = true; }
        function close() { networkPanel.visible = false; }
    }

    // IPC handler for Shell Settings Window
    IpcHandler {
        target: "settings"
        function toggle() { settingsWin.visible = !settingsWin.visible; }
        function open() { settingsWin.visible = true; }
        function close() { settingsWin.visible = false; }
    }

    // IPC handler for Power Menu
    IpcHandler {
        target: "power"
        function toggle() { powerMenu.visible = !powerMenu.visible; }
        function open() { powerMenu.visible = true; }
        function close() { powerMenu.visible = false; }
    }

    // IPC handler for Media Popup Flyout
    IpcHandler {
        target: "media"
        function toggle() { mediaPopup.visible = !mediaPopup.visible; }
        function open() { mediaPopup.visible = true; }
        function close() { mediaPopup.visible = false; }
    }
}
