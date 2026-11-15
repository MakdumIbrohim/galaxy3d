import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    required property var theme
    property string activeSsid: ""
    property string activeIp: ""
    property string selectedSsid: ""
    property int selectedSignal: 0
    property string selectedSecurity: "WPA2"
    property string selectedChan: ""
    property string selectedBssid: ""
    property bool isConnecting: false
    property string connectionError: ""
    property var networkModel: null

    signal connectRequested(string ssid, string password)
    signal disconnectRequested()
    signal relaySelected(string ssid, int signal, string security, string chan, string bssid)

    color: Qt.rgba(root.theme.crust.r, root.theme.crust.g, root.theme.crust.b, 0.5)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        // Deck Target Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 36; height: 36; radius: 10
                color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.2)
                border.color: root.theme.accent
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰄛"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 16
                    color: root.theme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "RELAY CONSOLE"
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: 12
                    color: root.theme.text
                }
                Text {
                    text: "COMMAND DECK & AUTHENTICATION"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    color: root.theme.overlay0
                }
            }

            Rectangle {
                width: 75; height: 20; radius: 10
                color: Qt.rgba(root.theme.surface1.r, root.theme.surface1.g, root.theme.surface1.b, 0.6)
                Text {
                    anchors.centerIn: parent
                    text: "HUD v2.5"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    font.bold: true
                    color: root.theme.overlay0
                }
            }
        }

        Rectangle {
            height: 1
            Layout.fillWidth: true
            color: Qt.rgba(root.theme.surface1.r, root.theme.surface1.g, root.theme.surface1.b, 0.35)
        }

        // Target Info Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: targetCol.implicitHeight + 24
            radius: 12
            color: root.theme.surface0
            border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
            border.width: 1

            ColumnLayout {
                id: targetCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.selectedSsid !== "" ? root.selectedSsid : "No Relay Targeted"
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 14
                        color: root.theme.text
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: root.selectedSsid !== "" && root.selectedSsid === root.activeSsid
                        width: 72; height: 20; radius: 10
                        color: Qt.rgba(root.theme.green.r, root.theme.green.g, root.theme.green.b, 0.25)
                        border.color: root.theme.green
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "󰄬 CONNECTED"
                            font.family: "JetBrains Mono"; font.pixelSize: 7; font.bold: true
                            color: root.theme.green
                        }
                    }
                }

                // Signal Quality Gauge Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Signal SNR Quality"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.subtext0; Layout.fillWidth: true }
                        Text { text: root.selectedSignal + "%"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; color: root.theme.accent }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: root.theme.mantle

                        Rectangle {
                            width: parent.width * (Math.max(0, Math.min(100, root.selectedSignal)) / 100.0)
                            height: parent.height
                            radius: parent.radius
                            color: root.selectedSignal > 60 ? "#89b4fa" : (root.selectedSignal > 30 ? "#fab387" : "#f38ba8")
                        }
                    }
                }

                // Specs Grid
                GridLayout {
                    columns: 2
                    Layout.fillWidth: true
                    rowSpacing: 4
                    columnSpacing: 10

                    Text { text: "Band / Freq:"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.overlay0 }
                    Text { text: parseInt(root.selectedChan) > 14 ? "5.0 GHz (CH " + root.selectedChan + ")" : "2.4 GHz (CH " + root.selectedChan + ")"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.text }

                    Text { text: "Security:"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.overlay0 }
                    Text { text: root.selectedSecurity; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.text }

                    Text { text: "BSSID:"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.overlay0 }
                    Text { text: root.selectedBssid !== "" ? root.selectedBssid : "--:--:--:--"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.subtext0 }

                    Text { text: "Local IP:"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.overlay0 }
                    Text { text: root.selectedSsid === root.activeSsid ? root.activeIp : "Disconnected"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.teal }
                }
            }
        }

        // Error Banner if present
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            radius: 8
            color: Qt.rgba(root.theme.red.r, root.theme.red.g, root.theme.red.b, 0.22)
            border.color: root.theme.red
            border.width: 1
            visible: root.connectionError !== ""

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { text: "󰅚"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: root.theme.red }
                Text { text: root.connectionError; font.family: "JetBrains Mono"; font.pixelSize: 9; color: root.theme.text; elide: Text.ElideRight }
            }
        }

        // Connection Control Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // If connected to this network: Disconnect Button
            Rectangle {
                visible: root.selectedSsid !== "" && root.selectedSsid === root.activeSsid
                Layout.fillWidth: true
                height: 38
                radius: 10
                color: disconMa.containsMouse ? Qt.rgba(root.theme.red.r, root.theme.red.g, root.theme.red.b, 0.28) : root.theme.surface0
                border.color: root.theme.red
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "󰌙"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: root.theme.red }
                    Text { text: "Disconnect Relay"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: root.theme.red }
                }

                MouseArea {
                    id: disconMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.disconnectRequested()
                }
            }

            // If not connected: Password Input + Connect Button
            ColumnLayout {
                visible: root.selectedSsid !== "" && root.selectedSsid !== root.activeSsid
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    TextField {
                        id: passInput
                        Layout.fillWidth: true
                        height: 36
                        placeholderText: "Network security key..."
                        placeholderTextColor: root.theme.overlay0
                        color: root.theme.text
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        echoMode: showPassToggle.show ? TextInput.Normal : TextInput.Password
                        background: Rectangle {
                            radius: 8
                            color: root.theme.mantle
                            border.color: passInput.activeFocus ? root.theme.accent : root.theme.surface2
                            border.width: 1
                        }
                        onAccepted: root.connectRequested(root.selectedSsid, passInput.text)
                    }

                    Rectangle {
                        id: showPassToggle
                        property bool show: false
                        width: 36; height: 36; radius: 8
                        color: root.theme.surface0
                        border.color: root.theme.surface2
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: parent.show ? "󰈈" : "󰈂"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 14
                            color: root.theme.subtext0
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.show = !parent.show
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 10
                    color: connectMa.containsMouse ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.3) : root.theme.accent

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: root.isConnecting ? "󰑐" : "󰌘"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 14
                            color: root.theme.crust
                            rotation: root.isConnecting ? connAnim.angle : 0

                            NumberAnimation on rotation {
                                id: connAnim
                                property real angle: 0
                                running: root.isConnecting
                                loops: Animation.Infinite
                                from: 0; to: 360; duration: 900
                            }
                        }
                        Text {
                            text: root.isConnecting ? "Negotiating Handshake..." : "Establish Orbital Link"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.crust
                        }
                    }

                    MouseArea {
                        id: connectMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.connectRequested(root.selectedSsid, passInput.text)
                    }
                }
            }
        }

        // Quick Switcher Network List
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            Text {
                text: "ALL DISCOVERED RELAYS (" + (root.networkModel ? root.networkModel.count : 0) + ")"
                font.family: "JetBrains Mono"
                font.bold: true
                font.pixelSize: 10
                color: root.theme.overlay0
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: miniList
                    model: root.networkModel
                    spacing: 4

                    delegate: Rectangle {
                        readonly property bool isTarget: root.selectedSsid === model.ssid
                        width: miniList.width
                        height: 32
                        radius: 8
                        color: isTarget
                            ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.2)
                            : (miniMa.containsMouse ? Qt.rgba(root.theme.surface1.r, root.theme.surface1.g, root.theme.surface1.b, 0.45) : "transparent")
                        border.color: isTarget ? root.theme.accent : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: model.signal > 60 ? "󰤨" : (model.signal > 30 ? "󰤥" : "󰤢")
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 12
                                color: isTarget ? root.theme.accent : root.theme.subtext0
                            }

                            Text {
                                text: model.ssid
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                                font.bold: isTarget
                                color: isTarget ? root.theme.text : root.theme.subtext0
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: model.signal + "%"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8
                                color: root.theme.overlay0
                            }
                        }

                        MouseArea {
                            id: miniMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.relaySelected(model.ssid, model.signal, model.security, model.chan, model.bssid);
                            }
                        }
                    }
                }
            }
        }
    }
}
