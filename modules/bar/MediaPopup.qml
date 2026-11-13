import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../../theme"

PanelWindow {
    id: mediaWin
    visible: false

    WlrLayershell.namespace: "galaxy3d-media-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MatugenColors { id: theme }

    readonly property MprisPlayer activePlayer: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    function formatTime(seconds) {
        if (!seconds || isNaN(seconds) || seconds < 0) return "0:00";
        let m = Math.floor(seconds / 60);
        let s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // Dismiss on click outside
    MouseArea {
        anchors.fill: parent
        onClicked: mediaWin.visible = false
    }

    Rectangle {
        id: card
        x: 80
        y: 52
        width: 350
        implicitHeight: cardContent.implicitHeight + 28
        radius: 18
        color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.96)
        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.45)
        border.width: 1.5

        scale: mediaWin.visible ? 1.0 : 0.92
        opacity: mediaWin.visible ? 1.0 : 0.0
        Behavior on scale   { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: cardContent
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Top Row: Album Art + Track Info + Close
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 60
                    height: 60
                    radius: 10
                    color: theme.surface0
                    border.color: Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.3)
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: mediaWin.activePlayer && mediaWin.activePlayer.trackArtUrl ? mediaWin.activePlayer.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 22
                        color: theme.mauve
                        visible: !mediaWin.activePlayer || !mediaWin.activePlayer.trackArtUrl
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: mediaWin.activePlayer ? (mediaWin.activePlayer.trackTitle || "Tidak Ada Judul") : "Tidak Ada Media"
                        font.family: "JetBrains Mono"
                        font.weight: Font.Bold
                        font.pixelSize: 13
                        color: theme.text
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: mediaWin.activePlayer ? (mediaWin.activePlayer.trackArtist || "Unknown Artist") : "Putar lagu untuk melihat info"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        color: theme.subtext0
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: mediaWin.activePlayer ? (mediaWin.activePlayer.trackAlbum || (mediaWin.activePlayer.playbackState === MprisPlaybackState.Playing ? "Memutar" : "Jeda")) : ""
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        color: theme.overlay0
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Text {
                    text: "󰅖"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 14
                    color: theme.subtext0
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mediaWin.visible = false
                    }
                }
            }

            // Progress / Seek Bar
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: mediaWin.activePlayer && mediaWin.activePlayer.length > 0

                Slider {
                    id: seekSlider
                    Layout.fillWidth: true
                    from: 0
                    to: mediaWin.activePlayer ? mediaWin.activePlayer.length : 1
                    value: mediaWin.activePlayer ? mediaWin.activePlayer.position : 0
                    onMoved: if (mediaWin.activePlayer) mediaWin.activePlayer.position = value
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: mediaWin.formatTime(mediaWin.activePlayer ? mediaWin.activePlayer.position : 0)
                        font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.overlay0
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: mediaWin.formatTime(mediaWin.activePlayer ? mediaWin.activePlayer.length : 0)
                        font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.overlay0
                    }
                }
            }

            // Controls Row (Previous, Play/Pause, Next)
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                Layout.alignment: Qt.AlignHCenter

                Item { Layout.fillWidth: true }

                Text {
                    text: "󰒮"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 20
                    color: theme.text
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (mediaWin.activePlayer) mediaWin.activePlayer.previous()
                    }
                }

                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: theme.blue

                    Text {
                        anchors.centerIn: parent
                        text: mediaWin.activePlayer && mediaWin.activePlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 18
                        color: theme.crust
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (mediaWin.activePlayer) mediaWin.activePlayer.togglePlaying()
                    }
                }

                Text {
                    text: "󰒭"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 20
                    color: theme.text
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (mediaWin.activePlayer) mediaWin.activePlayer.next()
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
