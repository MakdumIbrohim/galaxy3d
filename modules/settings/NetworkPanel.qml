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

    property bool isScanning: false
    property string activeSsid: ""
    property string activeIp: ""
    property int activeSignal: 0
    property string activeSecurity: "WPA2"
    property string connectionError: ""

    property string selectedSsid: ""
    property string selectedSecurity: ""
    property bool isConnecting: false

    ListModel {
        id: networkListModel
    }

    function scanNetworks() {
        if (isScanning) return;
        isScanning = true;
        connectionError = "";
        networkScanner.running = false;
        networkScanner.running = true;
    }

    function connectToNetwork(ssid, password, user) {
        if (ssid.trim() === "") return;
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
        Quickshell.execDetached(["bash", "-c", "nmcli con down id '" + activeSsid + "' || nmcli dev disconnect wlan0"]);
        activeSsid = "";
        scanNetworks();
    }

    // Network Scanner Process via nmcli
    Process {
        id: networkScanner
        command: ["bash", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                networkListModel.clear();
                let lines = this.text.trim().split("\n");
                let seen = {};
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split(":");
                    if (parts.length >= 4) {
                        let inUse = parts[0] === "*";
                        let ssid = parts[1].trim();
                        let signal = parseInt(parts[2]) || 0;
                        let sec = parts[3].trim() || "Open";

                        if (ssid === "") continue;
                        if (inUse) {
                            networkWindow.activeSsid = ssid;
                            networkWindow.activeSignal = signal;
                            networkWindow.activeSecurity = sec;
                        }
                        if (!seen[ssid]) {
                            seen[ssid] = true;
                            networkListModel.append({
                                "ssid": ssid,
                                "signal": signal,
                                "security": sec,
                                "isConnected": inUse,
                                "isSaved": false
                            });
                        }
                    }
                }
                networkWindow.isScanning = false;
            }
        }
    }

    // IP Reader Process
    Process {
        id: ipReader
        running: networkWindow.visible
        command: ["bash", "-c", "ip -4 addr show dev $(nmcli -t -f DEVICE,TYPE dev | grep ':wifi' | cut -d: -f1 | head -n1) 2>/dev/null | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' | head -n1 || echo '192.168.1.42'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let ip = this.text.trim();
                if (ip !== "") networkWindow.activeIp = ip;
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
                    networkWindow.connectionError = "Gagal terhubung: Sandi salah atau sinyal lemah.";
                } else {
                    networkWindow.connectionError = "";
                    networkWindow.selectedSsid = "";
                    networkWindow.scanNetworks();
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            scanNetworks();
            ipReader.running = false;
            ipReader.running = true;
        }
    }

    // Backdrop dismissal
    MouseArea {
        anchors.fill: parent
        onClicked: networkWindow.visible = false
    }

    // Main Modal Card
    Rectangle {
        id: panelCard
        width: 480
        height: Math.min(680, parent.height - 80)
        anchors.centerIn: parent
        radius: 18
        color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.96)
        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.4)
        border.width: 1.5

        MouseArea {
            anchors.fill: parent
            // Prevent clicks inside modal from closing it
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // --- Header Toolbar ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "󰤨"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 20
                    color: theme.blue
                }

                Text {
                    text: "Satelit & Jaringan Wi-Fi"
                    font.family: "JetBrains Mono"
                    font.weight: Font.Bold
                    font.pixelSize: 15
                    color: theme.text
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: rescanMouse.containsMouse ? theme.surface1 : theme.surface0
                    border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.3)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 16
                        color: networkWindow.isScanning ? theme.mauve : theme.subtext0
                        rotation: networkWindow.isScanning ? scanAnim.angle : 0
                    }

                    NumberAnimation on rotation {
                        id: scanAnim
                        property real angle: 0
                        running: networkWindow.isScanning
                        loops: Animation.Infinite
                        from: 0; to: 360; duration: 900
                    }

                    MouseArea {
                        id: rescanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: networkWindow.scanNetworks()
                    }
                }

                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: closeMouse.containsMouse ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.25) : theme.surface0
                    border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.3)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 14
                        color: theme.text
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: networkWindow.visible = false
                    }
                }
            }

            // --- Status Aktif Saat Ini ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: activeLayout.implicitHeight + 18
                radius: 12
                color: networkWindow.activeSsid !== ""
                    ? Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.12)
                    : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.4)
                border.color: networkWindow.activeSsid !== ""
                    ? Qt.rgba(theme.teal.r, theme.teal.g, theme.teal.b, 0.35)
                    : Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.4)
                border.width: 1

                RowLayout {
                    id: activeLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        width: 38; height: 38; radius: 10
                        color: networkWindow.activeSsid !== "" ? theme.teal : theme.surface1
                        Text {
                            anchors.centerIn: parent
                            text: networkWindow.activeSsid !== "" ? "󰤨" : "󰤮"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 20
                            color: theme.crust
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Text {
                                text: networkWindow.activeSsid !== "" ? networkWindow.activeSsid : "Tidak Terhubung"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: 13
                                color: theme.text
                            }
                            Rectangle {
                                visible: networkWindow.activeSsid !== ""
                                width: 56; height: 18; radius: 9
                                color: Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.25)
                                Text {
                                    anchors.centerIn: parent
                                    text: "Aktif"
                                    font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true
                                    color: theme.green
                                }
                            }
                        }

                        Text {
                            text: networkWindow.activeSsid !== ""
                                ? "IP: " + networkWindow.activeIp + "  |  Sinyal: " + networkWindow.activeSignal + "%  |  " + networkWindow.activeSecurity
                                : "Silakan pilih jaringan dari daftar di bawah untuk terhubung."
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            color: theme.subtext0
                        }
                    }

                    Button {
                        visible: networkWindow.activeSsid !== ""
                        text: "Putuskan"
                        contentItem: Text {
                            text: parent.text; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true
                            color: theme.red; horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            radius: 8; color: parent.hovered ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.2) : theme.surface0
                            border.color: theme.red; border.width: 1
                        }
                        onClicked: networkWindow.disconnectActive()
                    }
                }
            }

            // --- Error Banner ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 8
                color: Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.18)
                border.color: theme.red
                border.width: 1
                visible: networkWindow.connectionError !== ""

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "󰅚"; font.family: "Iosevka Nerd Font"; font.pixelSize: 14; color: theme.red }
                    Text { text: networkWindow.connectionError; font.family: "JetBrains Mono"; font.pixelSize: 11; color: theme.text }
                }
            }

            // --- Header Daftar Jaringan ---
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Jaringan Tersedia"
                    font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: 12
                    color: theme.subtext0
                    Layout.fillWidth: true
                }
                Text {
                    visible: networkWindow.isScanning
                    text: "Memindai frekuensi..."
                    font.family: "JetBrains Mono"; font.pixelSize: 10; font.italic: true
                    color: theme.mauve
                }
            }

            // --- List Jaringan ---
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: netListView
                    model: networkListModel
                    spacing: 8

                    delegate: Rectangle {
                        id: netItemCard
                        width: netListView.width
                        implicitHeight: isExpanded ? expandedForm.implicitHeight + 60 : 48
                        radius: 10
                        color: isExpanded
                            ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.6)
                            : (itemMa.containsMouse ? Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.8) : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.35))
                        border.color: isConnected
                            ? theme.teal
                            : (isExpanded ? theme.blue : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.2))
                        border.width: isConnected || isExpanded ? 1.5 : 1

                        readonly property bool isExpanded: networkWindow.selectedSsid === model.ssid

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: model.signal > 75 ? "󰤨" : (model.signal > 50 ? "󰤥" : (model.signal > 25 ? "󰤢" : "󰤟"))
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 16
                                    color: model.isConnected ? theme.teal : theme.blue
                                }

                                Text {
                                    text: model.ssid
                                    font.family: "JetBrains Mono"
                                    font.weight: model.isConnected ? Font.Bold : Font.Medium
                                    font.pixelSize: 12
                                    color: theme.text
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: model.security === "Open" ? "󰌿" : "󰌾"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 14
                                    color: model.security === "Open" ? theme.green : theme.overlay0
                                }

                                Text {
                                    text: model.signal + "%"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
                                    color: theme.subtext0
                                }
                            }

                            // Expander Connection Form
                            ColumnLayout {
                                id: expandedForm
                                visible: netItemCard.isExpanded && !model.isConnected
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle { height: 1; Layout.fillWidth: true; color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.3) }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    TextField {
                                        id: passInput
                                        Layout.fillWidth: true
                                        height: 34
                                        placeholderText: "Masukkan kata sandi..."
                                        placeholderTextColor: theme.overlay0
                                        color: theme.text
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 11
                                        echoMode: showPassBtn.show ? TextInput.Normal : TextInput.Password
                                        background: Rectangle {
                                            radius: 8; color: theme.mantle; border.color: theme.surface2; border.width: 1
                                        }
                                    }

                                    Rectangle {
                                        id: showPassBtn
                                        property bool show: false
                                        width: 34; height: 34; radius: 8
                                        color: theme.surface0; border.color: theme.surface2; border.width: 1
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

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Button {
                                        Layout.fillWidth: true
                                        text: networkWindow.isConnecting ? "Menghubungkan..." : "Hubungkan"
                                        enabled: !networkWindow.isConnecting
                                        contentItem: Text {
                                            text: parent.text; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true
                                            color: theme.crust; horizontalAlignment: Text.AlignHCenter
                                        }
                                        background: Rectangle {
                                            radius: 8; color: theme.blue
                                        }
                                        onClicked: networkWindow.connectToNetwork(model.ssid, passInput.text, "")
                                    }

                                    Button {
                                        text: "Batal"
                                        contentItem: Text {
                                            text: parent.text; font.family: "JetBrains Mono"; font.pixelSize: 11
                                            color: theme.text; horizontalAlignment: Text.AlignHCenter
                                        }
                                        background: Rectangle {
                                            radius: 8; color: theme.surface0; border.color: theme.surface2; border.width: 1
                                        }
                                        onClicked: networkWindow.selectedSsid = ""
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: itemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            visible: !netItemCard.isExpanded
                            onClicked: {
                                if (!model.isConnected) {
                                    networkWindow.selectedSsid = model.ssid;
                                    networkWindow.selectedSecurity = model.security;
                                }
                            }
                        }
                    }
                }
            }

            // --- Tombol Jaringan Tersembunyi (Hidden SSID) ---
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 10
                color: hiddenMa.containsMouse ? theme.surface1 : theme.surface0
                border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.3)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "󰌾"; font.family: "Iosevka Nerd Font"; font.pixelSize: 13; color: theme.mauve }
                    Text { text: "Hubungkan ke Jaringan Tersembunyi (Hidden SSID)"; font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true; color: theme.text }
                }

                MouseArea {
                    id: hiddenMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["notify-send", "Jaringan", "Gunakan 'nmcli dev wifi connect <SSID> hidden yes'"])
                }
            }
        }
    }
}
