import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "network"

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

    ListModel { id: networkListModel }
    ListModel { id: btDeviceModel }

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

    // Main Orbital Radar Card
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

        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

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

            // 1. Top Command & Mode Deck
            NetworkHeader {
                Layout.fillWidth: true
                height: 64
                theme: theme
                activeMode: networkWindow.activeMode
                isScanning: networkWindow.isScanning
                onModeChanged: function(newMode) {
                    networkWindow.activeMode = newMode;
                    if (newMode === "wifi") networkWindow.scanNetworks();
                    else if (newMode === "bt") networkWindow.scanBluetooth();
                    else networkWindow.checkEthernet();
                }
                onScanRequested: {
                    if (networkWindow.activeMode === "wifi") networkWindow.scanNetworks();
                    else if (networkWindow.activeMode === "bt") networkWindow.scanBluetooth();
                    else networkWindow.checkEthernet();
                }
                onCloseRequested: networkWindow.visible = false
            }

            Rectangle {
                height: 1
                Layout.fillWidth: true
                color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.45)
            }

            // 2. Viewport: Radar Field + Command Console
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Orbital Radar Field
                RadarField {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    theme: theme
                    activeMode: networkWindow.activeMode
                    activeSsid: networkWindow.activeSsid
                    activeIp: networkWindow.activeIp
                    selectedSsid: networkWindow.selectedSsid
                    btPowered: networkWindow.btPowered
                    ethCarrier: networkWindow.ethCarrier
                    networkModel: networkListModel
                    btModel: btDeviceModel
                    onRelaySelected: function(ssid, signal, security, chan, bssid) {
                        networkWindow.selectedSsid = ssid;
                        networkWindow.selectedSignal = signal;
                        networkWindow.selectedSecurity = security;
                        networkWindow.selectedChan = chan;
                        networkWindow.selectedBssid = bssid;
                    }
                }

                // Vertical Divider
                Rectangle {
                    width: 1
                    Layout.fillHeight: true
                    color: Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.45)
                }

                // Holographic Command & Connection Console
                ConnectionConsole {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 360
                    theme: theme
                    activeSsid: networkWindow.activeSsid
                    activeIp: networkWindow.activeIp
                    selectedSsid: networkWindow.selectedSsid
                    selectedSignal: networkWindow.selectedSignal
                    selectedSecurity: networkWindow.selectedSecurity
                    selectedChan: networkWindow.selectedChan
                    selectedBssid: networkWindow.selectedBssid
                    isConnecting: networkWindow.isConnecting
                    connectionError: networkWindow.connectionError
                    networkModel: networkListModel
                    onConnectRequested: function(ssid, pass) {
                        networkWindow.connectToNetwork(ssid, pass);
                    }
                    onDisconnectRequested: networkWindow.disconnectActive()
                    onRelaySelected: function(ssid, signal, security, chan, bssid) {
                        networkWindow.selectedSsid = ssid;
                        networkWindow.selectedSignal = signal;
                        networkWindow.selectedSecurity = security;
                        networkWindow.selectedChan = chan;
                        networkWindow.selectedBssid = bssid;
                    }
                }
            }
        }
    }
}
