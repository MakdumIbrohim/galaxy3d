pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    signal toggleLauncher()
    signal openLauncher()
    signal closeLauncher()

    signal toggleNetwork()
    signal openNetwork()
    signal closeNetwork()

    signal toggleSettings()
    signal openSettings()
    signal closeSettings()

    signal togglePower()
    signal openPower()
    signal closePower()

    signal toggleMedia()
    signal openMedia()
    signal closeMedia()

    signal randomWallpaper()
    signal wallpaperChanged(string path)

    // Dynamic Theme Configuration
    property bool isDarkMode: true
    property string activeAccent: "Mauve"
    property string topbarStyle: "cyber"
    property string currentWallpaper: ""
    property bool dndEnabled: false

    Caching { id: paths }

    Process {
        id: initConfReader
        running: true
        command: ["bash", "-c", "cat " + paths.configDir + "/wallpaper.conf 2>/dev/null || echo '' ; echo '---' ; cat " + paths.configDir + "/accent.conf 2>/dev/null || echo 'Mauve' ; echo '---' ; cat " + paths.configDir + "/mode.conf 2>/dev/null || echo 'dark' ; echo '---' ; cat " + paths.configDir + "/topbar_style.conf 2>/dev/null || echo 'cyber'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split("---");
                if (parts.length >= 4) {
                    let wp = parts[0].trim();
                    let acc = parts[1].trim();
                    let md = parts[2].trim();
                    let st = parts[3].trim();
                    if (wp !== "") root.currentWallpaper = wp;
                    if (acc !== "") root.activeAccent = acc;
                    if (md !== "") root.isDarkMode = (md !== "light");
                    if (st !== "") root.topbarStyle = st;
                }
            }
        }
    }

    function setDarkMode(dark) {
        root.isDarkMode = dark;
        Quickshell.execDetached(["bash", "-c", "echo '" + (dark ? "dark" : "light") + "' > " + paths.configDir + "/mode.conf"]);
    }

    function setAccent(accentName) {
        root.activeAccent = accentName;
        Quickshell.execDetached(["bash", "-c", "echo '" + accentName + "' > " + paths.configDir + "/accent.conf"]);
    }

    function setTopbarStyle(style) {
        if (style === "cyber" || style === "tactical" || style === "capsule") {
            root.topbarStyle = style;
            Quickshell.execDetached(["bash", "-c", "echo '" + style + "' > " + paths.configDir + "/topbar_style.conf"]);
        }
    }

    function setWallpaper(path) {
        if (!path || path.trim() === "") return;
        root.currentWallpaper = path;
        root.wallpaperChanged(path);
        Quickshell.execDetached(["bash", "-c", "echo '" + path + "' > " + paths.configDir + "/wallpaper.conf"]);
    }

    function setDnd(enabled) {
        root.dndEnabled = enabled;
        Quickshell.execDetached(["bash", "-c", "echo '" + (enabled ? "1" : "0") + "' > " + paths.configDir + "/dnd.conf"]);
    }
}
