pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool enabled: true

    function play(soundId) {
        if (!root.enabled) return;
        Quickshell.execDetached(["canberra-gtk-play", "-i", soundId]);
    }

    function playAppFound() {
        play("message-new-instant");
    }

    function playNoMatch() {
        play("dialog-warning");
    }

    function playLaunch() {
        play("service-login");
    }
}
