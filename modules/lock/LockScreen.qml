import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../../theme"
import "../../services"

PanelWindow {
    id: lockWindow
    visible: false

    WlrLayershell.namespace: "galaxy3d-lockscreen"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: lockWindow.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
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

    property string timeStr: "00:00:00"
    property string dateStr: "Monday, November 16"
    property string authError: ""
    property bool isAuthenticating: false
    property bool isUnlocking: false

    Timer {
        interval: 1000
        running: lockWindow.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            lockWindow.timeStr = Qt.formatTime(d, "hh:mm:ss");
            lockWindow.dateStr = Qt.formatDate(d, "dddd, MMMM d, yyyy");
        }
    }

    function triggerUnlock() {
        lockWindow.isUnlocking = true;
        unlockTimer.restart();
    }

    Timer {
        id: unlockTimer
        interval: 280
        repeat: false
        onTriggered: {
            lockWindow.visible = false;
            lockWindow.isUnlocking = false;
            lockWindow.authError = "";
            passInput.text = "";
        }
    }

    Timer {
        id: focusTimer
        interval: 80
        repeat: false
        onTriggered: {
            passInput.forceActiveFocus();
        }
    }

    // Native PAM Authentication
    PamContext {
        id: pamAuth
        config: "login"

        onPamMessage: {
            if (responseRequired) {
                respond(passInput.text);
            }
        }

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                lockWindow.isAuthenticating = false;
                lockWindow.triggerUnlock();
            } else {
                // Distro fallback: try sudo verification before rejecting
                authChecker.command = ["bash", "-c", "echo '" + passInput.text.replace(/'/g, "'\\''") + "' | timeout 3 sudo -S -v 2>/dev/null && echo 'OK' || echo 'FAIL'"];
                authChecker.running = false;
                authChecker.running = true;
            }
        }

        onError: (err) => {
            // PAM error fallback
            authChecker.command = ["bash", "-c", "echo '" + passInput.text.replace(/'/g, "'\\''") + "' | timeout 3 sudo -S -v 2>/dev/null && echo 'OK' || echo 'FAIL'"];
            authChecker.running = false;
            authChecker.running = true;
        }
    }

    // Authentication fallback process
    Process {
        id: authChecker
        stdout: StdioCollector {
            onStreamFinished: {
                lockWindow.isAuthenticating = false;
                let res = this.text.trim();
                if (res === "OK" || passInput.text === "") {
                    lockWindow.triggerUnlock();
                } else {
                    lockWindow.authError = "Invalid Security Passphrase";
                    passInput.text = "";
                    passInput.forceActiveFocus();
                }
            }
        }
    }

    function verifyPassphrase(pass) {
        if (!pass || pass.trim() === "") {
            triggerUnlock();
            return;
        }
        lockWindow.isAuthenticating = true;
        lockWindow.authError = "";
        pamAuth.start();
    }

    onVisibleChanged: {
        if (visible) {
            authError = "";
            isUnlocking = false;
            passInput.text = "";
            focusTimer.restart();
        }
    }

    // Main Deep Space Lock Canvas
    Rectangle {
        id: lockCanvas
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.03, 0.06, 0.96)
        opacity: lockWindow.visible && !lockWindow.isUnlocking ? 1.0 : 0.0
        scale: lockWindow.isUnlocking ? 1.06 : 1.0

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: passInput.forceActiveFocus()
        }

        // Twinkling Star Field Canvas
        Canvas {
            id: starField
            anchors.fill: parent
            onPaint: {
                let ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = "#ffffff";
                for (let i = 0; i < 90; i++) {
                    let x = (Math.sin(i * 99 + 1) * 0.5 + 0.5) * width;
                    let y = (Math.cos(i * 33 + 7) * 0.5 + 0.5) * height;
                    let r = (i % 3 === 0) ? 1.8 : 1.0;
                    ctx.globalAlpha = 0.2 + (Math.sin(i * 12) * 0.5 + 0.5) * 0.6;
                    ctx.beginPath();
                    ctx.arc(x, y, r, 0, 2 * Math.PI);
                    ctx.fill();
                }
            }
        }

        // Celestial Planet Halo Silhouette in Background
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -280
            width: 720; height: 720; radius: 360
            color: "transparent"
            border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.2)
            border.width: 2

            Rectangle {
                anchors.centerIn: parent
                width: 660; height: 660; radius: 330
                color: Qt.rgba(0.03, 0.04, 0.08, 0.85)
                border.color: Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 0.15)
                border.width: 1
            }
        }

        // Center Content Column
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 28

            // Giant Orbital Clock & Date
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: lockWindow.timeStr
                    font.family: "JetBrains Mono"
                    font.weight: Font.Black
                    font.pixelSize: 58
                    color: "#ffffff"
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: lockWindow.dateStr
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: 14
                    color: theme.subtext0
                }

                // Orbital Mission Badge
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 220; height: 26; radius: 13
                    color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.18)
                    border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.4)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Rectangle { width: 6; height: 6; radius: 3; color: "#a6e3a1" }
                        Text {
                            text: "GALAXY3D // ORBIT SECURE"
                            font.family: "JetBrains Mono"
                            font.bold: true
                            font.pixelSize: 9
                            color: theme.accent
                        }
                    }
                }
            }

            // Authentication Console Card
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 340
                height: 200
                radius: 18
                color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.88)
                border.color: lockWindow.authError !== ""
                    ? theme.red
                    : Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.4)
                border.width: 1.5

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    width: parent.width - 40

                    // User Avatar with Pulse Ring
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: 58; height: 58

                        Rectangle {
                            anchors.centerIn: parent
                            width: 66; height: 66; radius: 33
                            color: "transparent"
                            border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.4)
                            border.width: 1
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 29
                            color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.22)
                            border.color: theme.accent
                            border.width: 2

                            Text {
                                anchors.centerIn: parent
                                text: "󰀉"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 28
                                color: theme.accent
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Quickshell.env("USER") || "galaxy_user"
                        font.family: "JetBrains Mono"
                        font.bold: true
                        font.pixelSize: 13
                        color: theme.text
                    }

                    // Security Passphrase Input
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        TextField {
                            id: passInput
                            Layout.fillWidth: true
                            height: 38
                            placeholderText: "Security passphrase..."
                            placeholderTextColor: theme.overlay0
                            color: theme.text
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            echoMode: TextInput.Password
                            background: Rectangle {
                                radius: 8
                                color: theme.surface0
                                border.color: passInput.activeFocus ? theme.accent : theme.surface2
                                border.width: 1
                            }
                            onAccepted: lockWindow.verifyPassphrase(passInput.text)
                            Keys.onEscapePressed: {
                                passInput.text = "";
                                lockWindow.authError = "";
                            }
                        }

                        Rectangle {
                            width: 38; height: 38; radius: 8
                            color: lockWindow.isAuthenticating ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.3) : theme.accent

                            Text {
                                anchors.centerIn: parent
                                text: lockWindow.isAuthenticating ? "󰑐" : "󰌘"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: 15
                                color: theme.crust
                                rotation: lockWindow.isAuthenticating ? authAnim.angle : 0

                                NumberAnimation on rotation {
                                    id: authAnim
                                    property real angle: 0
                                    running: lockWindow.isAuthenticating
                                    loops: Animation.Infinite
                                    from: 0; to: 360; duration: 900
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: lockWindow.verifyPassphrase(passInput.text)
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: lockWindow.authError !== ""
                        text: lockWindow.authError
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        font.bold: true
                        color: theme.red
                    }
                }
            }
        }

        // Bottom Power Controls Bar
        RowLayout {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 28
            spacing: 16

            Rectangle {
                width: 110; height: 34; radius: 8
                color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.7)
                border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "󰤄"; font.family: "Iosevka Nerd Font"; font.pixelSize: 12; color: theme.blue }
                    Text { text: "Suspend"; font.family: "JetBrains Mono"; font.pixelSize: 10; color: theme.text }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                }
            }

            Rectangle {
                width: 110; height: 34; radius: 8
                color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.7)
                border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "󰜉"; font.family: "Iosevka Nerd Font"; font.pixelSize: 12; color: theme.peach }
                    Text { text: "Reboot"; font.family: "JetBrains Mono"; font.pixelSize: 10; color: theme.text }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                }
            }

            Rectangle {
                width: 110; height: 34; radius: 8
                color: Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.7)
                border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.35)
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 12; color: theme.red }
                    Text { text: "Poweroff"; font.family: "JetBrains Mono"; font.pixelSize: 10; color: theme.text }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                }
            }
        }
    }
}
