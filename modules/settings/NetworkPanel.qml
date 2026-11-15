import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../theme"
import "../../services"

PanelWindow {
    id: networkWindow
    visible: false

    WlrLayershell.namespace: "galaxy3d-network-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: networkWindow.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MatugenColors { id: theme }
    Caching { id: paths }

    property string activeMode: "wifi" // "wifi" | "bt" | "eth"
    property bool isScanning: false
    property string activeSsid: ""
    property string activeIp: ""
    property int activeSignal: 0
    property string activeSecurity: "WPA2"
    property string activeChan: "149"
    property string activeBssid: ""
    property string connectionError: ""

    property string selectedSsid: ""
    property int selectedSignal: 0
    property string selectedSecurity: "WPA2"
    property string selectedChan: ""
    property string selectedBssid: ""
    property bool isConnecting: false

    // Bluetooth properties
    property bool btPowered: false
    property string activeBtDevice: ""

    // Ethernet properties
    property bool ethCarrier: false
    property string ethSpeed: "1000 Mbps"
    property string ethIp: ""

    ListModel {
        id: networkListModel
    }

    ListModel {
        id: btDeviceModel
    }

    function scanNetworks() {
        if (isScanning) return;
        isScanning = true;
        connectionError = "";
        networkScanner.running = false;
        networkScanner.running = true;
    }

    function scanBluetooth() {
        btScanner.running = false;
        btScanner.running = true;
    }

    function checkEthernet() {
        ethReader.running = false;
        ethReader.running = true;
    }

    function connectToNetwork(ssid, password) {
        if (!ssid || ssid.trim() === "") return;
        isConnecting = true;
        connectionError = "";
        let cmd = password !== ""
            ? "nmcli dev wifi connect '" + ssid + "' password '" + password + "'"
            : "nmcli dev wifi connect '" + ssid + "'";
        connectProcess.command = ["bash", "-c", cmd];
        connectProcess.running = false;
        connectProcess.running = true;
    }

    function disconnectActive() {
        Quickshell.execDetached(["bash", "-c", "nmcli con down id '" + activeSsid + "' 2>/dev/null || nmcli dev disconnect wlan0 2>/dev/null"]);
        activeSsid = "";
        scanNetworks();
    }

    // Network Scanner Process via nmcli
    Process {
        id: networkScanner
        command: ["bash", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,CHAN,BSSID dev wifi list --rescan yes 2>/dev/null || nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,CHAN,BSSID dev wifi list 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                networkListModel.clear();
                let lines = this.text.trim().split("\n");
                let seen = {};
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split(":");
                    if (parts.length >= 5) {
                        let inUse = parts[0] === "*";
                        let ssid = parts[1].trim();
                        let signal = parseInt(parts[2]) || 0;
                        let sec = parts[3].trim() || "Open";
                        let chan = parts[4].trim() || "1";
                        // Reassemble BSSID if split by colon
                        let bssid = parts.slice(5).join(":").replace(/\\/g, "").trim();

                        if (ssid === "") continue;
                        if (inUse) {
                            networkWindow.activeSsid = ssid;
                            networkWindow.activeSignal = signal;
                            networkWindow.activeSecurity = sec;
                            networkWindow.activeChan = chan;
                            networkWindow.activeBssid = bssid;
                            if (networkWindow.selectedSsid === "") {
                                networkWindow.selectedSsid = ssid;
                                networkWindow.selectedSignal = signal;
                                networkWindow.selectedSecurity = sec;
                                networkWindow.selectedChan = chan;
                                networkWindow.selectedBssid = bssid;
                            }
                        }
                        if (!seen[ssid]) {
                            seen[ssid] = true;
                            networkListModel.append({
                                "ssid": ssid,
                                "signal": signal,
                                "security": sec,
                                "chan": chan,
                                "bssid": bssid,
                                "isConnected": inUse
                            });
                        }
                    }
                }
                if (networkWindow.selectedSsid === "" && networkListModel.count > 0) {
                    let first = networkListModel.get(0);
                    networkWindow.selectedSsid = first.ssid;
                    networkWindow.selectedSignal = first.signal;
                    networkWindow.selectedSecurity = first.security;
                    networkWindow.selectedChan = first.chan;
                    networkWindow.selectedBssid = first.bssid;
                }
                networkWindow.isScanning = false;
            }
        }
    }

    // IP Reader Process
    Process {
        id: ipReader
        running: networkWindow.visible
        command: ["bash", "-c", "ip -4 addr show dev $(nmcli -t -f DEVICE,TYPE dev 2>/dev/null | grep ':wifi' | cut -d: -f1 | head -n1) 2>/dev/null | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' | head -n1 || echo '192.168.1.42'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let ip = this.text.trim();
                if (ip !== "") networkWindow.activeIp = ip;
            }
        }
    }

    // Bluetooth Scanner Process
    Process {
        id: btScanner
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'POWER:YES' || echo 'POWER:NO' ; bluetoothctl devices 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                btDeviceModel.clear();
                let lines = this.text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let l = lines[i].trim();
                    if (l === "POWER:YES") networkWindow.btPowered = true;
                    else if (l === "POWER:NO") networkWindow.btPowered = false;
                    else if (l.startsWith("Device ")) {
                        let parts = l.split(" ");
                        let mac = parts[1] || "";
                        let name = parts.slice(2).join(" ") || mac;
                        btDeviceModel.append({ "mac": mac, "name": name });
                    }
                }
            }
        }
    }

    // Ethernet Reader Process
    Process {
        id: ethReader
        command: ["bash", "-c", "ip -br link 2>/dev/null | grep -E '^en|^eth' | head -n1 ; ip -4 addr show dev $(ip -br link 2>/dev/null | grep -E '^en|^eth' | awk '{print $1}' | head -n1) 2>/dev/null | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines[0]) {
                    networkWindow.ethCarrier = lines[0].includes("UP");
                }
                if (lines[1]) {
                    networkWindow.ethIp = lines[1].trim();
                }
            }
        }
    }

    // Connect Execution Process
    Process {
        id: connectProcess
        stdout: StdioCollector {
            onStreamFinished: {
                networkWindow.isConnecting = false;
                let txt = this.text.trim();
                if (txt.toLowerCase().includes("error") || txt.toLowerCase().includes("fail")) {
                    networkWindow.connectionError = "Satellite link failed: Incorrect network passphrase or low SNR.";
                } else {
                    networkWindow.connectionError = "";
                    networkWindow.scanNetworks();
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            scanNetworks();
            scanBluetooth();
            checkEthernet();
            ipReader.running = false;
            ipReader.running = true;
        }
    }

    // Backdrop with smooth fade
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.03, 0.06, 0.78)
        opacity: networkWindow.visible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: networkWindow.visible = false
        }
    }

    // ========================================================
    // MAIN ORBITAL SATELLITE RADAR VIEWPORT
    // ========================================================
    Rectangle {
        id: radarPanelCard
        width: Math.min(1080, parent.width - 40)
        height: Math.min(740, parent.height - 40)
        anchors.centerIn: parent
        radius: 22
        color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.95)
        border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.45)
        border.width: 1.5
        clip: true

        scale: networkWindow.visible ? 1.0 : 0.94
        opacity: networkWindow.visible ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Top Accent Glow Strip
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: theme.accent
            opacity: 0.85
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ========================================================
            // TOP COMMAND & MODE DECK
            // ========================================================
            Rectangle {
                Layout.fillWidth: true
                height: 64
                color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.75)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 16

                    // Brand & Radar Header
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 38
                            height: 38
                            radius: 10
                            color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2)
                            border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.45)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰤨"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 20
                                color: theme.accent
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            RowLayout {
                                spacing: 6
                                Text {
                                    text: "SATELLITE RADAR"
                                    font.family: "JetBrains Mono"
                                    font.bold: true
                                    font.pixelSize: 13
                                    color: theme.text
                                }
                                Rectangle {
                                    width: 6; height: 6; radius: 3
                                    color: "#a6e3a1"
                                }
                            }
                            Text {
                                text: "FREQUENCY & TELEMETRY INTERCEPTION"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8
                                color: theme.overlay0
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Mode Switcher (Capsule Segmented Control)
                    Rectangle {
                        width: 330
                        height: 36
                        radius: 10
                        color: theme.surface0
                        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            spacing: 2

                            // 1. Wi-Fi Radar Option
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: networkWindow.activeMode === "wifi" ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.22) : "transparent"
                                border.color: networkWindow.activeMode === "wifi" ? theme.accent : "transparent"
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "󰤨"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: networkWindow.activeMode === "wifi" ? theme.accent : theme.subtext0 }
                                    Text { text: "Wi-Fi"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: networkWindow.activeMode === "wifi"; color: networkWindow.activeMode === "wifi" ? theme.text : theme.subtext0 }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        networkWindow.activeMode = "wifi";
                                        networkWindow.scanNetworks();
                                    }
                                }
                            }

                            // 2. Bluetooth Option
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: networkWindow.activeMode === "bt" ? Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.22) : "transparent"
                                border.color: networkWindow.activeMode === "bt" ? theme.blue : "transparent"
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "󰂯"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: networkWindow.activeMode === "bt" ? theme.blue : theme.subtext0 }
                                    Text { text: "Bluetooth"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: networkWindow.activeMode === "bt"; color: networkWindow.activeMode === "bt" ? theme.text : theme.subtext0 }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        networkWindow.activeMode = "bt";
                                        networkWindow.scanBluetooth();
                                    }
                                }
                            }

                            // 3. Ethernet Option
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: networkWindow.activeMode === "eth" ? Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.22) : "transparent"
                                border.color: networkWindow.activeMode === "eth" ? theme.teal : "transparent"
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "󰈀"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: networkWindow.activeMode === "eth" ? theme.teal : theme.subtext0 }
                                    Text { text: "Ethernet"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: networkWindow.activeMode === "eth"; color: networkWindow.activeMode === "eth" ? theme.text : theme.subtext0 }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        networkWindow.activeMode = "eth";
                                        networkWindow.checkEthernet();
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Rescan Ping Button
                    Rectangle {
                        width: 110
                        height: 36
                        radius: 10
                        color: rescanMa.containsMouse ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.25) : theme.surface0
                        border.color: rescanMa.containsMouse ? theme.accent : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰑐"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 14
                                color: networkWindow.isScanning ? theme.accent : theme.subtext0
                                rotation: networkWindow.isScanning ? pingAnim.angle : 0

                                NumberAnimation on rotation {
                                    id: pingAnim
                                    property real angle: 0
                                    running: networkWindow.isScanning
                                    loops: Animation.Infinite
                                    from: 0; to: 360; duration: 900
                                }
                            }
                            Text {
                                text: networkWindow.isScanning ? "Pinging..." : "Sweep Scan"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                                font.bold: true
                                color: theme.text
                            }
                        }

                        MouseArea {
                            id: rescanMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (networkWindow.activeMode === "wifi") networkWindow.scanNetworks();
                                else if (networkWindow.activeMode === "bt") networkWindow.scanBluetooth();
                                else networkWindow.checkEthernet();
                            }
                        }
                    }

                    // Close Radar Button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 10
                        color: closeRadarMa.containsMouse ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.25) : theme.surface0
                        border.color: closeRadarMa.containsMouse ? theme.red : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 14
                            color: closeRadarMa.containsMouse ? theme.red : theme.subtext0
                        }

                        MouseArea {
                            id: closeRadarMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: networkWindow.visible = false
                        }
                    }
                }
            }

            Rectangle {
                height: 1
                Layout.fillWidth: true
                color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.45)
            }

            // ========================================================
            // MAIN VIEWPORT: RADAR FIELD + COMMAND CONSOLE
            // ========================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // ----------------------------------------------------
                // 1. ORBITAL RADAR FIELD (LEFT / CENTER)
                // ----------------------------------------------------
                Item {
                    id: radarField
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    clip: true

                    // Cosmic Radar Grid Lines
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 40, 620)
                        height: 1
                        color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.15)
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 1
                        height: Math.min(parent.height - 40, 620)
                        color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.15)
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
                            border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.16)
                            border.width: 1

                            Text {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.topMargin: 4
                                text: modelData.label
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8
                                color: Qt.rgba(theme.subtext0.r, theme.subtext0.g, theme.subtext0.b, 0.45)
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
                                GradientStop { position: 0.0; color: theme.accent }
                                GradientStop { position: 0.7; color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.4) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        NumberAnimation on rotation {
                            id: sweepAnim
                            property real angle: 0
                            running: networkWindow.visible
                            loops: Animation.Infinite
                            from: 0; to: 360; duration: 4500
                        }
                    }

                    // ================================================
                    // CENTRAL RADAR BASE CORE
                    // ================================================
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
                            border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.3)
                            border.width: 1.5
                            scale: pulseAnim.scaleVal

                            SequentialAnimation on scale {
                                id: pulseAnim
                                property real scaleVal: 1.0
                                running: networkWindow.visible
                                loops: Animation.Infinite
                                NumberAnimation { to: 1.15; duration: 1200; easing.type: Easing.OutSine }
                                NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InSine }
                            }
                        }

                        // Central Station Orb
                        Rectangle {
                            anchors.fill: parent
                            radius: 48
                            color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.9)
                            border.color: theme.accent
                            border.width: 2

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: networkWindow.activeMode === "wifi" ? (networkWindow.activeSsid !== "" ? "󰤨" : "󰤮")
                                        : (networkWindow.activeMode === "bt" ? "󰂯" : "󰈀")
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 22
                                    color: theme.accent
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: networkWindow.activeMode === "wifi"
                                        ? (networkWindow.activeSsid !== "" ? "LINKED" : "SEEKING")
                                        : (networkWindow.activeMode === "bt" ? (networkWindow.btPowered ? "ON" : "OFF") : (networkWindow.ethCarrier ? "ONLINE" : "OFFLINE"))
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: theme.text
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
                            color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.85)
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                            border.width: 1

                            Text {
                                id: coreLabel
                                anchors.centerIn: parent
                                text: networkWindow.activeMode === "wifi"
                                    ? (networkWindow.activeSsid !== "" ? networkWindow.activeSsid : "Radar Idle")
                                    : (networkWindow.activeMode === "bt" ? "BlueZ Controller" : (networkWindow.ethCarrier ? "Gigabit Eth" : "No Cable"))
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                font.bold: true
                                color: theme.accent
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // ================================================
                    // ORBITING SATELLITE RELAY NODES (WI-FI)
                    // ================================================
                    Repeater {
                        model: networkWindow.activeMode === "wifi" ? networkListModel : 0

                        delegate: Item {
                            id: satNode
                            readonly property real totalNodes: Math.max(1, networkListModel.count)
                            readonly property real baseAngle: (index / totalNodes) * 2 * Math.PI - (Math.PI / 2)
                            readonly property real normSignal: Math.max(0.08, Math.min(1.0, (model.signal || 50) / 100.0))
                            readonly property real orbitRadius: 115 + (1.0 - normSignal) * 170

                            readonly property bool isSelected: networkWindow.selectedSsid === model.ssid
                            readonly property bool isConnected: model.isConnected

                            width: satBadge.width
                            height: satBadge.height

                            x: (radarField.width / 2) + Math.cos(baseAngle) * orbitRadius - (width / 2)
                            y: (radarField.height / 2) + Math.sin(baseAngle) * orbitRadius - (height / 2)

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
                                border.color: theme.accent
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
                                    ? Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.28)
                                    : (isSelected ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.26) : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.85))
                                border.color: isConnected
                                    ? theme.teal
                                    : (isSelected ? theme.accent : (satMa.containsMouse ? theme.surface2 : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)))
                                border.width: isConnected || isSelected ? 1.5 : 1

                                RowLayout {
                                    id: satRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    // Blinking beacon dot
                                    Rectangle {
                                        width: 8; height: 8; radius: 4
                                        color: isConnected ? "#a6e3a1" : (model.signal > 60 ? "#89b4fa" : (model.signal > 30 ? "#fab387" : "#f38ba8"))
                                    }

                                    Text {
                                        text: model.signal > 75 ? "󰤨" : (model.signal > 50 ? "󰤥" : (model.signal > 25 ? "󰤢" : "󰤟"))
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 13
                                        color: isConnected ? theme.teal : (isSelected ? theme.accent : theme.subtext0)
                                    }

                                    Text {
                                        text: model.ssid
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 10
                                        font.bold: isConnected || isSelected
                                        color: isConnected ? theme.text : (isSelected ? theme.text : theme.subtext0)
                                        elide: Text.ElideRight
                                    }

                                    // Band indicator (5G vs 2.4G)
                                    Rectangle {
                                        width: 22; height: 14; radius: 4
                                        color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.6)
                                        Text {
                                            anchors.centerIn: parent
                                            text: parseInt(model.chan) > 14 ? "5G" : "2.4"
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 7
                                            font.bold: true
                                            color: parseInt(model.chan) > 14 ? theme.mauve : theme.overlay0
                                        }
                                    }

                                    Text {
                                        text: model.security === "Open" ? "󰌿" : "󰌾"
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 11
                                        color: model.security === "Open" ? theme.green : theme.overlay0
                                    }

                                    Text {
                                        text: model.signal + "%"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 9
                                        color: theme.overlay0
                                    }
                                }

                                MouseArea {
                                    id: satMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        networkWindow.selectedSsid = model.ssid;
                                        networkWindow.selectedSignal = model.signal;
                                        networkWindow.selectedSecurity = model.security;
                                        networkWindow.selectedChan = model.chan;
                                        networkWindow.selectedBssid = model.bssid;
                                    }
                                }
                            }
                        }
                    }

                    // ================================================
                    // ORBITING BLUETOOTH BEACONS (IF BT MODE)
                    // ================================================
                    Repeater {
                        model: networkWindow.activeMode === "bt" ? btDeviceModel : 0

                        delegate: Item {
                            readonly property real totalNodes: Math.max(1, btDeviceModel.count)
                            readonly property real baseAngle: (index / totalNodes) * 2 * Math.PI - (Math.PI / 2)
                            readonly property real orbitRadius: 160 + (index % 2 === 0 ? 30 : -20)

                            width: btBadge.width
                            height: btBadge.height
                            x: (radarField.width / 2) + Math.cos(baseAngle) * orbitRadius - (width / 2)
                            y: (radarField.height / 2) + Math.sin(baseAngle) * orbitRadius - (height / 2)

                            Rectangle {
                                id: btBadge
                                width: btRow.implicitWidth + 24
                                height: 32
                                radius: 16
                                color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.85)
                                border.color: theme.blue
                                border.width: 1

                                RowLayout {
                                    id: btRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: "󰂯"
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 13
                                        color: theme.blue
                                    }
                                    Text {
                                        text: model.name
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: theme.text
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

                // Vertical Divider
                Rectangle {
                    width: 1
                    Layout.fillHeight: true
                    color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.45)
                }

                // ----------------------------------------------------
                // 2. HOLOGRAPHIC COMMAND & CONNECTION DECK (RIGHT)
                // ----------------------------------------------------
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 360
                    color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.5)

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
                                color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2)
                                border.color: theme.accent
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄛"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 16
                                    color: theme.accent
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
                                    color: theme.text
                                }
                                Text {
                                    text: "COMMAND DECK & AUTHENTICATION"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 8
                                    color: theme.overlay0
                                }
                            }

                            Rectangle {
                                width: 75; height: 20; radius: 10
                                color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.6)
                                Text {
                                    anchors.centerIn: parent
                                    text: "HUD v2.5"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: theme.overlay0
                                }
                            }
                        }

                        Rectangle {
                            height: 1
                            Layout.fillWidth: true
                            color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.35)
                        }

                        // Target Info Card
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: targetCol.implicitHeight + 24
                            radius: 12
                            color: theme.surface0
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
                            border.width: 1

                            ColumnLayout {
                                id: targetCol
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: networkWindow.selectedSsid !== "" ? networkWindow.selectedSsid : "No Relay Targeted"
                                        font.family: "JetBrains Mono"
                                        font.bold: true
                                        font.pixelSize: 14
                                        color: theme.text
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        visible: networkWindow.selectedSsid !== "" && networkWindow.selectedSsid === networkWindow.activeSsid
                                        width: 72; height: 20; radius: 10
                                        color: Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.25)
                                        border.color: theme.green
                                        border.width: 1
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰄬 CONNECTED"
                                            font.family: "JetBrains Mono"; font.pixelSize: 7; font.bold: true
                                            color: theme.green
                                        }
                                    }
                                }

                                // Signal Quality Gauge Bar
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Signal SNR Quality"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.subtext0; Layout.fillWidth: true }
                                        Text { text: networkWindow.selectedSignal + "%"; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true; color: theme.accent }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 6
                                        radius: 3
                                        color: theme.mantle

                                        Rectangle {
                                            width: parent.width * (Math.max(0, Math.min(100, networkWindow.selectedSignal)) / 100.0)
                                            height: parent.height
                                            radius: parent.radius
                                            color: networkWindow.selectedSignal > 60 ? "#89b4fa" : (networkWindow.selectedSignal > 30 ? "#fab387" : "#f38ba8")
                                        }
                                    }
                                }

                                // Specs Grid
                                GridLayout {
                                    columns: 2
                                    Layout.fillWidth: true
                                    rowSpacing: 4
                                    columnSpacing: 10

                                    Text { text: "Band / Freq:"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.overlay0 }
                                    Text { text: parseInt(networkWindow.selectedChan) > 14 ? "5.0 GHz (CH " + networkWindow.selectedChan + ")" : "2.4 GHz (CH " + networkWindow.selectedChan + ")"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.text }

                                    Text { text: "Security:"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.overlay0 }
                                    Text { text: networkWindow.selectedSecurity; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.text }

                                    Text { text: "BSSID:"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.overlay0 }
                                    Text { text: networkWindow.selectedBssid !== "" ? networkWindow.selectedBssid : "--:--:--:--"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.subtext0 }

                                    Text { text: "Local IP:"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.overlay0 }
                                    Text { text: networkWindow.selectedSsid === networkWindow.activeSsid ? networkWindow.activeIp : "Disconnected"; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.teal }
                                }
                            }
                        }

                        // Error Banner if present
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 8
                            color: Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.22)
                            border.color: theme.red
                            border.width: 1
                            visible: networkWindow.connectionError !== ""

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "󰅚"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: theme.red }
                                Text { text: networkWindow.connectionError; font.family: "JetBrains Mono"; font.pixelSize: 9; color: theme.text; elide: Text.ElideRight }
                            }
                        }

                        // Connection Control Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // If connected to this network: Disconnect Button
                            Rectangle {
                                visible: networkWindow.selectedSsid !== "" && networkWindow.selectedSsid === networkWindow.activeSsid
                                Layout.fillWidth: true
                                height: 38
                                radius: 10
                                color: disconMa.containsMouse ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.28) : theme.surface0
                                border.color: theme.red
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text { text: "󰌙"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: theme.red }
                                    Text { text: "Disconnect Relay"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: theme.red }
                                }

                                MouseArea {
                                    id: disconMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: networkWindow.disconnectActive()
                                }
                            }

                            // If not connected: Password Input + Connect Button
                            ColumnLayout {
                                visible: networkWindow.selectedSsid !== "" && networkWindow.selectedSsid !== networkWindow.activeSsid
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
                                        placeholderTextColor: theme.overlay0
                                        color: theme.text
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 11
                                        echoMode: showPassToggle.show ? TextInput.Normal : TextInput.Password
                                        background: Rectangle {
                                            radius: 8
                                            color: theme.mantle
                                            border.color: passInput.activeFocus ? theme.accent : theme.surface2
                                            border.width: 1
                                        }
                                        onAccepted: networkWindow.connectToNetwork(networkWindow.selectedSsid, passInput.text)
                                    }

                                    Rectangle {
                                        id: showPassToggle
                                        property bool show: false
                                        width: 36; height: 36; radius: 8
                                        color: theme.surface0
                                        border.color: theme.surface2
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: parent.show ? "󰈈" : "󰈂"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 14
                                            color: theme.subtext0
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
                                    color: connectMa.containsMouse ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.3) : theme.accent

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 8
                                        Text {
                                            text: networkWindow.isConnecting ? "󰑐" : "󰌘"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 14
                                            color: theme.crust
                                            rotation: networkWindow.isConnecting ? connAnim.angle : 0

                                            NumberAnimation on rotation {
                                                id: connAnim
                                                property real angle: 0
                                                running: networkWindow.isConnecting
                                                loops: Animation.Infinite
                                                from: 0; to: 360; duration: 900
                                            }
                                        }
                                        Text {
                                            text: networkWindow.isConnecting ? "Negotiating Handshake..." : "Establish Orbital Link"
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: theme.crust
                                        }
                                    }

                                    MouseArea {
                                        id: connectMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: networkWindow.connectToNetwork(networkWindow.selectedSsid, passInput.text)
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
                                text: "ALL DISCOVERED RELAYS (" + networkListModel.count + ")"
                                font.family: "JetBrains Mono"
                                font.bold: true
                                font.pixelSize: 10
                                color: theme.overlay0
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                ListView {
                                    id: miniList
                                    model: networkListModel
                                    spacing: 4

                                    delegate: Rectangle {
                                        readonly property bool isTarget: networkWindow.selectedSsid === model.ssid
                                        width: miniList.width
                                        height: 32
                                        radius: 8
                                        color: isTarget
                                            ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2)
                                            : (miniMa.containsMouse ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.45) : "transparent")
                                        border.color: isTarget ? theme.accent : "transparent"
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8; anchors.rightMargin: 8
                                            spacing: 6

                                            Text {
                                                text: model.signal > 60 ? "󰤨" : (model.signal > 30 ? "󰤥" : "󰤢")
                                                font.family: "Iosevka Nerd Font"
                                                font.pixelSize: 12
                                                color: isTarget ? theme.accent : theme.subtext0
                                            }

                                            Text {
                                                text: model.ssid
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: 10
                                                font.bold: isTarget
                                                color: isTarget ? theme.text : theme.subtext0
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: model.signal + "%"
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: 8
                                                color: theme.overlay0
                                            }
                                        }

                                        MouseArea {
                                            id: miniMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                networkWindow.selectedSsid = model.ssid;
                                                networkWindow.selectedSignal = model.signal;
                                                networkWindow.selectedSecurity = model.security;
                                                networkWindow.selectedChan = model.chan;
                                                networkWindow.selectedBssid = model.bssid;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
