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


    function triggerRandomWallpaper() {
        Quickshell.execDetached(["bash", "-c", "find /usr/share/wallpapers/cachyos-wallpapers/ " + paths.home + "/Pictures/ -type f \\( -name '*.jpg' -o -name '*.png' \\) 2>/dev/null | shuf -n 1 > " + paths.configDir + "/wallpaper.conf"]);
        wpReader.running = false;
        wpReader.running = true;
    }

    Connections {
        target: ShellBridge
        function onWallpaperChanged(path) {
            root.wallpaperPath = path;
        }
        function onRandomWallpaper() {
            root.triggerRandomWallpaper();
        }
    }

    IpcHandler {
        target: "wallpaper"
        function set(path: string) {
            root.wallpaperPath = path;
            Quickshell.execDetached(["bash", "-c", "echo '" + path + "' > " + paths.configDir + "/wallpaper.conf"]);
        }
        function random() {
            root.triggerRandomWallpaper();
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

        // 4. Performant Twinkling Starfield (Batched GPU Rendering)
        Repeater {
            model: 220

            Rectangle {
                id: starCore

                readonly property real baseSize: 1.5 + Math.random() * 3.0
                width: baseSize
                height: baseSize
                radius: baseSize / 2

                color: {
                    let r = Math.random();
                    if (r > 0.85) return "#b4befe"; // soft cosmic blue
                    if (r > 0.70) return "#f9e2af"; // warm yellow
                    if (r > 0.55) return "#f5c2e7"; // nebula pink
                    return "#ffffff";
                }

                x: Math.random() * (root.width > 0 ? root.width : 1920)
                y: Math.random() * (root.height > 0 ? root.height : 1080)

                readonly property real minOpacity: 0.10 + Math.random() * 0.20
                readonly property real maxOpacity: 0.65 + Math.random() * 0.35
                readonly property int animDuration: 1200 + Math.round(Math.random() * 2800)

                opacity: minOpacity

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation {
                        from: starCore.minOpacity
                        to: starCore.maxOpacity
                        duration: starCore.animDuration
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        from: starCore.maxOpacity
                        to: starCore.minOpacity
                        duration: starCore.animDuration
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }
}
