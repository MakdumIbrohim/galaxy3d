import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: root

    property string wallpaperPath: ""

    Caching { id: paths }

    WlrLayershell.namespace: "stars-bg"
    WlrLayershell.layer: WlrLayer.Background

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    focusable: false
    exclusionMode: ExclusionMode.Ignore
    mask: null
    color: "#010206"

    Process {
        id: wpReader
        running: true
        command: ["bash", "-c", "cat " + paths.configDir + "/wallpaper.conf 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = this.text.trim();
                if (p !== "") root.wallpaperPath = p;
            }
        }
    }

    IpcHandler {
        target: "wallpaper"
        function set(path: string): void {
            root.wallpaperPath = path;
            Quickshell.execDetached(["bash", "-c", "echo '" + path + "' > " + paths.configDir + "/wallpaper.conf"]);
        }
        function random(): void {
            Quickshell.execDetached(["bash", "-c", "find " + paths.home + "/Pictures/Wallpapers/ -type f \\( -name '*.jpg' -o -name '*.png' \\) 2>/dev/null | shuf -n 1 > " + paths.configDir + "/wallpaper.conf"]);
            wpReader.running = false;
            wpReader.running = true;
        }
    }

    Item {
        anchors.fill: parent

        // 1. Cosmic Night Sky Gradient Base
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#010206" }
                GradientStop { position: 0.45; color: "#030612" }
                GradientStop { position: 0.80; color: "#070e24" }
                GradientStop { position: 1.0; color: "#0b1536" }
            }
        }

        // 2. Wallpaper Image (sky/space wallpaper)
        Image {
            id: bgWallpaper
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: root.wallpaperPath !== ""
                ? (root.wallpaperPath.startsWith("/") ? "file://" + root.wallpaperPath : root.wallpaperPath)
                : ""
            visible: status === Image.Ready
            opacity: 0.70
            asynchronous: true
        }

        // 3. Vignette & Deep Space Atmosphere
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.01, 0.02, 0.05, 0.45)
            visible: bgWallpaper.visible
        }

        // 4. 800 Twinkling Stars
        Repeater {
            model: 800

            Rectangle {
                id: starCore

                width: 2.0 + Math.random() * 4
                height: width
                radius: width / 2

                color: Qt.rgba(0.95 + Math.random() * 0.05,
                               0.9  + Math.random() * 0.1,
                               0.8  + Math.random() * 0.2,
                               1.0)

                opacity: 0

                x: Math.random() * root.screen.width
                y: Math.random() * root.screen.height

                layer.enabled: true
                layer.effect: MultiEffect {
                    autoPaddingEnabled: true
                    shadowEnabled: true
                    shadowColor: starCore.color
                    shadowBlur: 2.0 + Math.random() * 4.0
                    shadowOpacity: starCore.opacity * 0.8
                }

                Timer {
                    id: blinkTimer
                    repeat: true
                    running: false

                    onTriggered: {
                        starCore.opacity = 0.05 + Math.random() * 0.95
                    }
                }

                Component.onCompleted: {
                    blinkTimer.interval = 400 + Math.random() * 3000
                    starCore.opacity = 0.05 + Math.random() * 0.95
                    blinkTimer.running = true
                }
            }
        }
    }
}
