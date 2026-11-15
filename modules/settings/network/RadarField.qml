import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    required property var theme
    property string activeMode: "wifi"
    property string activeSsid: ""
    property string activeIp: ""
    property string selectedSsid: ""
    property bool btPowered: false
    property bool ethCarrier: false
    property var networkModel: null
    property var btModel: null

    signal relaySelected(string ssid, int signal, string security, string chan, string bssid)

    clip: true

    // Cosmic Radar Grid Lines
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 620)
        height: 1
        color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.15)
    }
    Rectangle {
        anchors.centerIn: parent
        width: 1
        height: Math.min(parent.height - 40, 620)
        color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.15)
    }

    // Concentric Range Rings (25%, 50%, 75%, 100% signal)
    Repeater {
        model: [
            { "radius": 110, "label": "[ 100% RELAY ]" },
            { "radius": 175, "label": "[ 75% RANGE ]" },
            { "radius": 240, "label": "[ 50% ]" },
            { "radius": 300, "label": "[ 25% OUTER ]" }
        ]

        delegate: Rectangle {
            anchors.centerIn: parent
            width: modelData.radius * 2
            height: width
            radius: modelData.radius
            color: "transparent"
            border.color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.16)
            border.width: 1

            Text {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 4
                text: modelData.label
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                color: Qt.rgba(root.theme.subtext0.r, root.theme.subtext0.g, root.theme.subtext0.b, 0.45)
            }
        }
    }

    // Rotating Sonar Beam Sweep
    Item {
        id: sonarSweep
        anchors.centerIn: parent
        width: 600; height: 600

        Rectangle {
            width: 295
            height: 2
            x: parent.width / 2
            y: parent.height / 2
            transformOrigin: Item.Left
            rotation: sweepAnim.angle
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root.theme.accent }
                GradientStop { position: 0.7; color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.4) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        NumberAnimation on rotation {
            id: sweepAnim
            property real angle: 0
            running: root.visible
            loops: Animation.Infinite
            from: 0; to: 360; duration: 4500
        }
    }

    // Central Radar Base Core
    Item {
        id: centralCore
        anchors.centerIn: parent
        width: 96
        height: 96

        // Outer Pulse Glow Halo
        Rectangle {
            anchors.centerIn: parent
            width: 110; height: 110; radius: 55
            color: "transparent"
            border.color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.3)
            border.width: 1.5
            scale: pulseAnim.scaleVal

            SequentialAnimation on scale {
                id: pulseAnim
                property real scaleVal: 1.0
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation { to: 1.15; duration: 1200; easing.type: Easing.OutSine }
                NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InSine }
            }
        }

        // Central Station Orb
        Rectangle {
            anchors.fill: parent
            radius: 48
            color: Qt.rgba(root.theme.crust.r, root.theme.crust.g, root.theme.crust.b, 0.9)
            border.color: root.theme.accent
            border.width: 2

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.activeMode === "wifi" ? (root.activeSsid !== "" ? "󰤨" : "󰤮")
                        : (root.activeMode === "bt" ? "󰂯" : "󰈀")
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 22
                    color: root.theme.accent
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.activeMode === "wifi"
                        ? (root.activeSsid !== "" ? "LINKED" : "SEEKING")
                        : (root.activeMode === "bt" ? (root.btPowered ? "ON" : "OFF") : (root.ethCarrier ? "ONLINE" : "OFFLINE"))
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    font.bold: true
                    color: root.theme.text
                }
            }
        }

        // Active IP / SSID Readout Pill below core
        Rectangle {
            anchors.top: centralCore.bottom
            anchors.horizontalCenter: centralCore.horizontalCenter
            anchors.topMargin: 10
            width: Math.max(140, coreLabel.implicitWidth + 20)
            height: 22
            radius: 11
            color: Qt.rgba(root.theme.surface0.r, root.theme.surface0.g, root.theme.surface0.b, 0.85)
            border.color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)
            border.width: 1

            Text {
                id: coreLabel
                anchors.centerIn: parent
                text: root.activeMode === "wifi"
                    ? (root.activeSsid !== "" ? root.activeSsid : "Radar Idle")
                    : (root.activeMode === "bt" ? "BlueZ Controller" : (root.ethCarrier ? "Gigabit Eth" : "No Cable"))
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                font.bold: true
                color: root.theme.accent
                elide: Text.ElideRight
            }
        }
    }

    // Orbiting Satellite Relay Nodes (Wi-Fi)
    Repeater {
        model: root.activeMode === "wifi" ? root.networkModel : null

        delegate: Item {
            id: satNode
            readonly property real totalNodes: Math.max(1, (root.networkModel ? root.networkModel.count : 1))
            readonly property real baseAngle: (index / totalNodes) * 2 * Math.PI - (Math.PI / 2)
            readonly property real normSignal: Math.max(0.08, Math.min(1.0, (model.signal || 50) / 100.0))
            readonly property real orbitRadius: 115 + (1.0 - normSignal) * 170

            readonly property bool isSelected: root.selectedSsid === model.ssid
            readonly property bool isConnected: model.isConnected

            width: satBadge.width
            height: satBadge.height

            x: (root.width / 2) + Math.cos(baseAngle) * orbitRadius - (width / 2)
            y: (root.height / 2) + Math.sin(baseAngle) * orbitRadius - (height / 2)

            scale: satMa.containsMouse ? 1.08 : (isSelected ? 1.04 : 1.0)
            Behavior on scale { NumberAnimation { duration: 150 } }

            // Targeting Reticle if Selected
            Rectangle {
                visible: isSelected
                anchors.centerIn: parent
                width: parent.width + 12
                height: parent.height + 12
                radius: 14
                color: "transparent"
                border.color: root.theme.accent
                border.width: 1
                opacity: 0.7
            }

            // Satellite Capsule Badge
            Rectangle {
                id: satBadge
                width: satRow.implicitWidth + 24
                height: 34
                radius: 17
                color: isConnected
                    ? Qt.rgba(root.theme.teal.r, root.theme.teal.g, root.theme.teal.b, 0.28)
                    : (isSelected ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.26) : Qt.rgba(root.theme.surface0.r, root.theme.surface0.g, root.theme.surface0.b, 0.85))
                border.color: isConnected
                    ? root.theme.teal
                    : (isSelected ? root.theme.accent : (satMa.containsMouse ? root.theme.surface2 : Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.4)))
                border.width: isConnected || isSelected ? 1.5 : 1

                RowLayout {
                    id: satRow
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: isConnected ? "#a6e3a1" : (model.signal > 60 ? "#89b4fa" : (model.signal > 30 ? "#fab387" : "#f38ba8"))
                    }

                    Text {
                        text: model.signal > 75 ? "󰤨" : (model.signal > 50 ? "󰤥" : (model.signal > 25 ? "󰤢" : "󰤟"))
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 13
                        color: isConnected ? root.theme.teal : (isSelected ? root.theme.accent : root.theme.subtext0)
                    }

                    Text {
                        text: model.ssid
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        font.bold: isConnected || isSelected
                        color: isConnected ? root.theme.text : (isSelected ? root.theme.text : root.theme.subtext0)
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: 22; height: 14; radius: 4
                        color: Qt.rgba(root.theme.surface1.r, root.theme.surface1.g, root.theme.surface1.b, 0.6)
                        Text {
                            anchors.centerIn: parent
                            text: parseInt(model.chan) > 14 ? "5G" : "2.4"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 7
                            font.bold: true
                            color: parseInt(model.chan) > 14 ? root.theme.mauve : root.theme.overlay0
                        }
                    }

                    Text {
                        text: model.security === "Open" ? "󰌿" : "󰌾"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 11
                        color: model.security === "Open" ? root.theme.green : root.theme.overlay0
                    }

                    Text {
                        text: model.signal + "%"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        color: root.theme.overlay0
                    }
                }

                MouseArea {
                    id: satMa
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

    // Orbiting Bluetooth Beacons (If Bluetooth Mode)
    Repeater {
        model: root.activeMode === "bt" ? root.btModel : null

        delegate: Item {
            readonly property real totalNodes: Math.max(1, (root.btModel ? root.btModel.count : 1))
            readonly property real baseAngle: (index / totalNodes) * 2 * Math.PI - (Math.PI / 2)
            readonly property real orbitRadius: 160 + (index % 2 === 0 ? 30 : -20)

            width: btBadge.width
            height: btBadge.height
            x: (root.width / 2) + Math.cos(baseAngle) * orbitRadius - (width / 2)
            y: (root.height / 2) + Math.sin(baseAngle) * orbitRadius - (height / 2)

            Rectangle {
                id: btBadge
                width: btRow.implicitWidth + 24
                height: 32
                radius: 16
                color: Qt.rgba(root.theme.surface0.r, root.theme.surface0.g, root.theme.surface0.b, 0.85)
                border.color: root.theme.blue
                border.width: 1

                RowLayout {
                    id: btRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰂯"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 13
                        color: root.theme.blue
                    }
                    Text {
                        text: model.name
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        font.bold: true
                        color: root.theme.text
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["bluetoothctl", "connect", model.mac]);
                        Quickshell.execDetached(["notify-send", "Bluetooth", "Connecting to " + model.name]);
                    }
                }
            }
        }
    }
}
