import QtQuick

QtObject {
    id: root
    property real currentWidth: 1366
    function s(val) {
        return Math.round(val * (currentWidth / 1920.0));
    }
}
