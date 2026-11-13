import QtQuick
import Quickshell

QtObject {
    id: root

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (root.home + "/.config")) + "/quickshell/galaxy3d"
    readonly property string qsDir: root.configDir
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (root.home + "/.cache")) + "/galaxy3d"
    readonly property string runDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/galaxy3d"

    function getRunDir(name) { return root.runDir; }
    function getCacheDir(name) { return root.cacheDir; }
}
