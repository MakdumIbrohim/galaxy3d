import QtQuick
import "../services"

QtObject {
    id: root

    readonly property bool isDark: ShellBridge.isDarkMode

    // Catppuccin Mocha (Dark) vs Catppuccin Latte (Light)
    property color base:      isDark ? "#11111b" : "#eff1f5"
    property color mantle:    isDark ? "#181825" : "#e6e9ef"
    property color crust:     isDark ? "#0c0c14" : "#dce0e8"
    property color surface0:  isDark ? "#1e1e2e" : "#ccd0da"
    property color surface1:  isDark ? "#313244" : "#bcc0cc"
    property color surface2:  isDark ? "#45475a" : "#acb0be"
    property color overlay0:  isDark ? "#6c7086" : "#9ca0b0"
    property color text:      isDark ? "#cdd6f4" : "#4c4f69"
    property color subtext0:  isDark ? "#a6adc8" : "#6c6f85"

    // Accents
    property color blue:      isDark ? "#89b4fa" : "#1e66f5"
    property color mauve:     isDark ? "#cba6f7" : "#8839ef"
    property color teal:      isDark ? "#94e2d5" : "#179299"
    property color peach:     isDark ? "#fab387" : "#fe640b"
    property color yellow:    isDark ? "#f9e2af" : "#df8e1d"
    property color sapphire:  isDark ? "#74c7ec" : "#209fb5"
    property color green:     isDark ? "#a6e3a1" : "#40a02b"
    property color red:       isDark ? "#f38ba8" : "#d20f39"
    property color maroon:    isDark ? "#eba0ac" : "#e64553"
    property color lavender:  isDark ? "#b4befe" : "#7287fd"
    property color sky:       isDark ? "#89dceb" : "#04a5e5"
    property color pink:      isDark ? "#f5c2e7" : "#ea76cb"
    property color flamingo:  isDark ? "#f2cdcd" : "#dd7878"
    property color rosewater: isDark ? "#f5e0dc" : "#dc8a78"

    // Primary system accent dynamic matching activeAccent
    property color accent: {
        switch (ShellBridge.activeAccent.toLowerCase()) {
            case "blue":     return blue;
            case "teal":     return teal;
            case "peach":    return peach;
            case "green":    return green;
            case "yellow":   return yellow;
            case "red":      return red;
            case "sapphire": return sapphire;
            default:         return mauve;
        }
    }
}
