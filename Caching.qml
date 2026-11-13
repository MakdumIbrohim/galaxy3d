import QtQuick
import Quickshell

QtObject {
    id: root
    readonly property string qsDir: "/home/makdumibrohim/.config/quickshell/galaxy3d"
    readonly property string serpantinumDir: "/home/makdumibrohim/.local/share/serpantinum/src"
    readonly property string runDir: "/tmp"
    readonly property string cacheDir: "/tmp"
    function getRunDir(name) { return "/tmp"; }
    function getCacheDir(name) { return "/tmp"; }
}
