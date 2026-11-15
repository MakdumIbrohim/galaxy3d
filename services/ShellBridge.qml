pragma Singleton
import QtQuick

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
}
