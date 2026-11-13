import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../services"

Item {
    id: root

    property string timeStr: ""
    property string fullDateStr: ""
    property string weatherIcon: ""
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
    property string volPercent: "0%"
    property string volIcon:    "󰕾"
    property bool   isMuted:    false
    property string batPercent: "100%"
    property string batIcon:    "󰁹"
    property string batStatus:  "Unknown"
    property bool   isDesktop:  false
    property string ethStatus:  "Ethernet"

    readonly property bool isWifiOn:     wifiStatus.toLowerCase() === "enabled" || wifiStatus.toLowerCase() === "on"
    readonly property bool isBtOn:       btStatus.toLowerCase()   === "enabled" || btStatus.toLowerCase()   === "on"
    readonly property bool showEthernet: ethStatus === "Connected" || (isDesktop && !isWifiOn)
    readonly property bool isSoundActive: !isMuted && parseInt(volPercent) > 0
    readonly property int  batCap:       parseInt(batPercent) || 0
    readonly property bool isCharging:   batStatus === "Charging" || batStatus === "Full"
    readonly property color batColor: {
        if (isCharging) return theme.green;
        if (batCap <= 20) return theme.red;
        return theme.text;
    }

    readonly property alias workspacesModel: workspacesModel
    property var musicData: ({ "status": "Stopped", "title": "", "artUrl": "", "timeStr": "" })
    readonly property bool isMusicActive: musicData.status === "Playing" && musicData.title !== ""

    MatugenColors { id: theme }
    Caching { id: paths }

    Process {
        id: weatherPoller
        command: [
            "bash", "-c",
            "echo \"$(" + paths.serpantinumDir + "/scripts/weather.sh --current-icon)\"\n" +
            "echo \"$(" + paths.serpantinumDir + "/scripts/weather.sh --current-temp)\"\n" +
            "echo \"$(" + paths.serpantinumDir + "/scripts/weather.sh --current-hex)\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 3) {
                    root.weatherIcon = lines[0];
                    root.weatherTemp = lines[1];
                    root.weatherHex  = lines[2] || theme.yellow;
                }
            }
        }
    }

    Process {
        id: detailedWeatherPoller
        command: ["bash", paths.serpantinumDir + "/scripts/weather.sh", "--json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { root.detailedWeatherData = JSON.parse(txt); } catch(e) {}
                }
            }
        }
    }

    Timer {
        interval: 150000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            weatherPoller.running = false; weatherPoller.running = true;
            detailedWeatherPoller.running = false; detailedWeatherPoller.running = true;
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            root.timeStr    = Qt.formatDateTime(d, "HH:mm:ss");
            root.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
        }
    }

    Process {
        id: kbPoller; running: true
        command: ["bash", "-c", paths.qsDir + "/watchers/kb_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = this.text.trim();
                if (t !== "") root.kbLayout = t;
                kbWaiter.running = false; kbWaiter.running = true;
            }
        }
    }
    Process { id: kbWaiter; command: ["bash", "-c", paths.qsDir + "/watchers/kb_wait.sh"]; onExited: { kbPoller.running = false; kbPoller.running = true; } }

    Process {
        id: audioPoller; running: true
        command: ["bash", "-c", paths.qsDir + "/watchers/audio_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = this.text.trim();
                if (t !== "") {
                    try {
                        let d = JSON.parse(t);
                        root.volPercent = d.volume.toString() + "%";
                        root.volIcon    = d.icon;
                        root.isMuted    = (d.is_muted === "true");
                    } catch(e) {}
                }
                audioWaiter.running = false; audioWaiter.running = true;
            }
        }
    }
    Process { id: audioWaiter; command: ["bash", "-c", paths.qsDir + "/watchers/audio_wait.sh"]; onExited: { audioPoller.running = false; audioPoller.running = true; } }

    Process {
        id: networkPoller; running: true
        command: ["bash", "-c", paths.qsDir + "/watchers/network_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = this.text.trim();
                if (t !== "") {
                    try {
                        let d = JSON.parse(t);
                        root.wifiStatus = d.status;
                        root.wifiIcon   = d.icon;
                        root.wifiSsid   = d.ssid;
                        root.ethStatus  = d.eth_status;
                    } catch(e) {}
                }
                networkWaiter.running = false; networkWaiter.running = true;
            }
        }
    }
    Process { id: networkWaiter; command: ["bash", "-c", paths.qsDir + "/watchers/network_wait.sh"]; onExited: { networkPoller.running = false; networkPoller.running = true; } }

    Process {
        id: btPoller; running: true
        command: ["bash", "-c", paths.qsDir + "/watchers/bt_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = this.text.trim();
                if (t !== "") {
                    try {
                        let d = JSON.parse(t);
                        root.btStatus = d.status;
                        root.btIcon   = d.icon;
                        root.btDevice = d.connected;
                    } catch(e) {}
                }
                btWaiter.running = false; btWaiter.running = true;
            }
        }
    }
    Process { id: btWaiter; command: ["bash", "-c", paths.qsDir + "/watchers/bt_wait.sh"]; onExited: { btPoller.running = false; btPoller.running = true; } }

    Process {
        id: batteryPoller; running: true
        command: ["bash", "-c", paths.qsDir + "/watchers/battery_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let t = this.text.trim();
                if (t !== "") {
                    try {
                        let d = JSON.parse(t);
                        root.batPercent = d.percent.toString() + "%";
                        root.batIcon    = d.icon;
                        root.batStatus  = d.status;
                    } catch(e) {}
                }
                batteryWaiter.running = false; batteryWaiter.running = true;
            }
        }
    }
    Process { id: batteryWaiter; command: ["bash", "-c", paths.qsDir + "/watchers/battery_wait.sh"]; onExited: { batteryPoller.running = false; batteryPoller.running = true; } }

    ListModel {
        id: workspacesModel
        property int activeIndex: 0
    }

    Process {
        id: wsDaemon
        command: ["bash", "-c", paths.serpantinumDir + "/scripts/workspaces.sh"]
        running: true
    }

    Process {
        id: wsReader
        running: true
        command: ["cat", paths.getRunDir("workspaces") + "/workspaces.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let newData = JSON.parse(txt);
                        while (workspacesModel.count < newData.length)
                            workspacesModel.append({ "wsId": "", "wsState": "" });
                        while (workspacesModel.count > newData.length)
                            workspacesModel.remove(workspacesModel.count - 1);
                        let newActive = -1;
                        for (let i = 0; i < newData.length; i++) {
                            if (newData[i].state === "active") newActive = i;
                            if (workspacesModel.get(i).wsState !== newData[i].state)
                                workspacesModel.setProperty(i, "wsState", newData[i].state);
                            if (workspacesModel.get(i).wsId !== newData[i].id.toString())
                                workspacesModel.setProperty(i, "wsId", newData[i].id.toString());
                        }
                        if (newActive !== -1 && workspacesModel.activeIndex !== newActive)
                            workspacesModel.activeIndex = newActive;
                    } catch(e) {}
                }
            }
        }
    }

    Process {
        id: wsWatcher
        running: true
        command: ["bash", "-c", "inotifywait -qq -e close_write,modify " + paths.getRunDir("workspaces") + "/workspaces.json"]
        onExited: {
            wsReader.running = false; wsReader.running = true;
            running = false; running = true;
        }
    }

    Process {
        id: musicPoller
        command: ["bash", "-c", "bash " + paths.qsDir + "/music/music_info.sh"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let d = JSON.parse(txt);
                        if (d.title !== root.musicData.title ||
                            d.status !== root.musicData.status ||
                            d.timeStr !== root.musicData.timeStr) {
                            root.musicData = d;
                        }
                    } catch(e) {}
                }
            }
        }
    }

    Process {
        id: mprisWatcher
        running: true
        command: ["bash", "-c", "dbus-monitor --session \"type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.mpris.MediaPlayer2.Player'\" \"type='signal',interface='org.mpris.MediaPlayer2.Player',member='Seeked'\" 2>/dev/null | grep -m 1 'member=' > /dev/null || sleep 2"]
        onExited: {
            musicPoller.running = false;
            musicPoller.running = true;
            running = false;
            running = true;
        }
    }

    Component.onCompleted: { musicPoller.running = true; }
}
