import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

Rectangle {
    id: root
    height: 34
    implicitWidth: Math.min(280, mediaLayout.implicitWidth + 22)
    radius: 17
    color: Qt.rgba(0.08, 0.08, 0.12, 0.85)
    border.color: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? Qt.rgba(0.54, 0.71, 0.98, 0.4) : Qt.rgba(1, 1, 1, 0.15)
    border.width: 1
    visible: activePlayer !== null

    readonly property MprisPlayer activePlayer: {
        const players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    RowLayout {
        id: mediaLayout
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Rectangle {
            width: 22
            height: 22
            radius: 11
            color: "#181825"
            clip: true

            Image {
                anchors.fill: parent
                source: root.activePlayer && root.activePlayer.trackArtUrl ? root.activePlayer.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                text: ""
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 11
                color: "#89b4fa"
                visible: !root.activePlayer || !root.activePlayer.trackArtUrl
            }
        }

        Text {
            Layout.fillWidth: true
            text: {
                if (!root.activePlayer) return "No Media";
                const title = root.activePlayer.trackTitle || "Unknown Track";
                const artist = root.activePlayer.trackArtist ? (" - " + root.activePlayer.trackArtist) : "";
                return title + artist;
            }
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: "#cdd6f4"
            elide: Text.ElideRight
        }

        Text {
            text: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 13
            color: "#89b4fa"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
            }
        }

        Text {
            text: "󰒭"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 12
            color: Qt.rgba(1, 1, 1, 0.6)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.activePlayer) root.activePlayer.next()
            }
        }
    }
}
