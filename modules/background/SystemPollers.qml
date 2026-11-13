import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../theme"
import "../../services"

Item {
    id: root

    property string timeStr: ""
    property string fullDateStr: ""
    property string weatherIcon: "󰖙"
    property string weatherTemp: "--°"
    property string weatherHex: theme.yellow
    property var detailedWeatherData: null

    property string kbLayout:   "us"
    property string wifiStatus: "Off"
    property string wifiIcon:   "󰤮"
    property string wifiSsid:   ""
    property string btStatus:   "Off"
    property string btIcon:     "󰂲"
    property string btDevice:   ""

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink].filter(n => n)
    }

    readonly property var sinkAudio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property int volNumber: sinkAudio ? Math.round(sinkAudio.volume * 100) : 0
    property string volPercent: volNumber + "%"
    property bool isMuted: sinkAudio ? sinkAudio.muted : false
    property string volIcon: isMuted || volNumber === 0 ? "󰝟" : (volNumber < 50 ? "󰖀" : "󰕾")
    readonly property bool isSoundActive: !isMuted && volNumber > 0

    property string batPercent: "100%"
    property string batIcon:    "󰁹"
    property string batStatus:  "Unknown"
    property bool   isDesktop:  false
    property string ethStatus:  "Ethernet"

    readonly property bool isWifiOn:     wifiStatus.toLowerCase() === "enabled" || wifiStatus.toLowerCase() === "on"
    readonly property bool isBtOn:       btStatus.toLowerCase()   === "enabled" || btStatus.toLowerCase()   === "on"
    readonly property bool showEthernet: ethStatus === "Connected" || (isDesktop && !isWifiOn)
    readonly property int  batCap:       parseInt(batPercent) || 0
    readonly property bool isCharging:   batStatus === "Charging" || batStatus === "Full"
    readonly property color batColor: {
        if (isCharging) return theme.green;
        if (batCap <= 20) return theme.red;
        return theme.text;
    }

    MatugenColors { id: theme }
    Caching { id: paths }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            root.timeStr     = Qt.formatDateTime(d, "HH:mm:ss");
            root.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
        }
    }

    Process {
        id: weatherPoller
        command: [paths.qsDir + "/services/galaxy3d-helper", "weather"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let d = JSON.parse(txt);
                        root.detailedWeatherData = d;
                        if (d.current) {
                            root.weatherIcon = d.current.icon || "󰖙";
                            root.weatherTemp = (d.current.temp || "--") + "°";
                            root.weatherHex  = d.current.hex || theme.yellow;
                        }
                    } catch(e) {}
                }
            }
        }
    }

    Timer {
        interval: 600000; running: true; repeat: true
        onTriggered: {
            weatherPoller.running = false;
            weatherPoller.running = true;
        }
    }

    Process {
        id: kbPoller
        command: ["bash", "-c", "hyprctl -j devices 2>/dev/null | python3 -c 'import sys,json; kbs=json.load(sys.stdin).get(\"keyboards\",[]); print(kbs[0].get(\"active_keymap\",\"us\")[:2].lower() if kbs else \"us\")'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let t = this.text.trim();
                if (t !== "") root.kbLayout = t;
            }
        }
    }

    Process {
        id: networkPoller
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE,CONNECTION dev 2>/dev/null | grep -E '^wifi:connected' || echo 'off'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let t = this.text.trim();
                if (t.startsWith("wifi:connected:")) {
                    root.wifiStatus = "on";
                    root.wifiIcon = "󰤨";
                    root.wifiSsid = t.replace("wifi:connected:", "");
                } else {
                    root.wifiStatus = "off";
                    root.wifiIcon = "󰤮";
                    root.wifiSsid = "";
                }
            }
        }
    }

    Process {
        id: btPoller
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'on' || echo 'off'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let t = this.text.trim();
                if (t === "on") {
                    root.btStatus = "on";
                    root.btIcon = "󰂯";
                } else {
                    root.btStatus = "off";
                    root.btIcon = "󰂲";
                }
            }
        }
    }

    Process {
        id: batteryPoller
        command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 1 && lines[0] !== "") {
                    root.batPercent = lines[0] + "%";
                    root.batStatus = lines.length >= 2 ? lines[1] : "Discharging";
                    root.batIcon = root.isCharging ? "󰂄" : (parseInt(lines[0]) > 20 ? "󰁹" : "󰂃");
                }
            }
        }
    }

    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: {
            kbPoller.running = false; kbPoller.running = true;
            networkPoller.running = false; networkPoller.running = true;
            btPoller.running = false; btPoller.running = true;
            batteryPoller.running = false; batteryPoller.running = true;
        }
    }
}
