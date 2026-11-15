pragma Singleton
import QtQuick
import Quickshell

Item {
    id: root

    function playClick() {
        if (!ShellBridge.sfxEnabled) return;
        Quickshell.execDetached(["bash", "-c", "pw-play /usr/share/sounds/ocean/stereo/button-pressed.oga 2>/dev/null || canberra-gtk-play -i button-pressed 2>/dev/null || true"]);
    }

    function playToggle() {
        if (!ShellBridge.sfxEnabled) return;
        Quickshell.execDetached(["bash", "-c", "pw-play /usr/share/sounds/ocean/stereo/button-pressed-modifier.oga 2>/dev/null || canberra-gtk-play -i button-toggle 2>/dev/null || true"]);
    }

    function playWarp() {
        if (!ShellBridge.sfxEnabled) return;
        Quickshell.execDetached(["bash", "-c", "pw-play /usr/share/sounds/ocean/stereo/desktop-login.oga 2>/dev/null || canberra-gtk-play -i desktop-login 2>/dev/null || true"]);
    }

    function playSuccess() {
        if (!ShellBridge.sfxEnabled) return;
        Quickshell.execDetached(["bash", "-c", "pw-play /usr/share/sounds/ocean/stereo/completion-success.oga 2>/dev/null || canberra-gtk-play -i complete 2>/dev/null || true"]);
    }
}
