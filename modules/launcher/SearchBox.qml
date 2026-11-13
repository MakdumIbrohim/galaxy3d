import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import "../../theme"

Rectangle {
    id: root

    property real introPhase: 1.0
    property alias text: searchInput.text
    property alias searchInput: searchInput

    signal searchModified(string query)
    signal downPressed()
    signal upPressed()
    signal returnPressed()
    signal escapePressed()

    function forceActiveFocus() {
        searchInput.forceActiveFocus();
    }

    MatugenColors { id: theme }
    Scaler { id: scaler; currentWidth: Screen.width }

    function s(val) {
        let res = scaler.s(val);
        return res > 0 ? res : val;
    }

    width: s(560)
    height: s(56)
    radius: s(28)
    color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.92)
    border.color: searchInput.activeFocus ? theme.mauve : theme.surface1
    border.width: s(1.5)

    opacity: root.introPhase
    transform: Translate { y: (1 - root.introPhase) * s(40) }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    layer.enabled: root.introPhase > 0.01
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.4
        shadowBlur: 1.5
        shadowVerticalOffset: s(4)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: s(20)
        anchors.rightMargin: s(20)
        spacing: s(12)

        Text {
            text: ""
            font.family: "Iosevka Nerd Font"
            font.pixelSize: s(18)
            color: searchInput.activeFocus ? theme.mauve : theme.subtext0
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        TextField {
            id: searchInput
            Layout.fillWidth: true
            Layout.fillHeight: true
            background: Item {}
            color: theme.text
            font.family: "JetBrains Mono"
            font.pixelSize: s(15)
            font.weight: Font.Medium
            selectByMouse: true

            placeholderText: "Search applications..."
            placeholderTextColor: theme.overlay0
            verticalAlignment: TextInput.AlignVCenter

            onTextChanged: root.searchModified(text)

            Keys.onDownPressed: {
                root.downPressed();
                event.accepted = true;
            }
            Keys.onUpPressed: {
                root.upPressed();
                event.accepted = true;
            }
            Keys.onReturnPressed: {
                root.returnPressed();
                event.accepted = true;
            }
            Keys.onEscapePressed: {
                root.escapePressed();
                event.accepted = true;
            }
        }

        Text {
            visible: searchInput.text.length > 0
            text: "󰅖"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: s(16)
            color: theme.subtext0
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    searchInput.text = "";
                    searchInput.forceActiveFocus();
                }
            }
        }
    }
}
