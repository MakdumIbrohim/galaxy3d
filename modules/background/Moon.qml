import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "bodies"
import "satellites"

PanelWindow {
    id: root

    property bool isSearchMode: false

    WlrLayershell.namespace: "galaxy3d-background"
    WlrLayershell.layer: WlrLayer.Bottom

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    focusable: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: null

    MatugenColors { id: mocha }

    readonly property color base:       mocha.base
    readonly property color mantle:     mocha.mantle      || mocha.base
    readonly property color crust:      mocha.crust
    readonly property color text:       mocha.text
    readonly property color subtext0:   mocha.subtext0
    readonly property color overlay0:   mocha.overlay0    || "#6c7086"
    readonly property color surface0:   mocha.surface0
    readonly property color surface1:   mocha.surface1
    readonly property color surface2:   mocha.surface2
    readonly property color blue:       mocha.blue        || "#89b4fa"
    readonly property color mauve:      mocha.mauve       || "#cba6f7"
    readonly property color teal:       mocha.teal        || "#94e2d5"
    readonly property color peach:      mocha.peach       || "#fab387"
    readonly property color green:      mocha.green       || "#a6e3a1"
    readonly property color red:        mocha.red         || "#f38ba8"
    readonly property color yellow:     mocha.yellow      || "#f9e2af"
    readonly property color sapphire:   mocha.sapphire    || "#74c7ec"

    SystemPollers {
        id: pollers
    }

    property alias timeStr: pollers.timeStr
    property alias fullDateStr: pollers.fullDateStr
    property alias weatherIcon: pollers.weatherIcon
    property alias weatherTemp: pollers.weatherTemp
    property alias weatherHex: pollers.weatherHex
    property alias detailedWeatherData: pollers.detailedWeatherData

    property bool weatherRingsActive: false
    property real independentCometAngle: 0
    property real earthAutoRotation: 0

    property real baseSphereRadius: 260
    property real zoomFactor: 1.0
    property real sphereRadius: baseSphereRadius * zoomFactor

    readonly property real satelliteZoom: zoomFactor
    readonly property real earthZoom:      Math.pow(zoomFactor, 1.25)
    readonly property real earthZOffset:  -5.0 + (zoomFactor - 1.0) * 0.4
    property real earthSphereRadius: 1150 * root.earthZoom

    property real targetRotX: -0.2
    property real targetRotY: 0
    property real targetCamX: 0.0
    property real targetCamY: 0.0

    property real rotX: -0.2
    property real rotY: 0
    property real camX: 0.0
    property real camY: 0.0

    readonly property real cosRx: Math.cos(root.rotX)
    readonly property real sinRx: Math.sin(root.rotX)
    readonly property real cosRy: Math.cos(root.rotY)
    readonly property real sinRy: Math.sin(root.rotY)

    readonly property real cosCx: Math.cos(root.camX)
    readonly property real sinCx: Math.sin(root.camX)
    readonly property real cosCy: Math.cos(root.camY)
    readonly property real sinCy: Math.sin(root.camY)

    property real sunValueX: 1.0
    property real sunValueY: 0.0
    readonly property real screenSunAngleDeg: Math.atan2(sunValueY, sunValueX) * 180 / Math.PI

    Behavior on zoomFactor { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    Shortcut {
        sequence: "Escape"
        enabled: root.weatherRingsActive
        onActivated: root.weatherRingsActive = false
    }

    property real easterEggAngle: 0
    property real gaugeAngle: Math.PI / 2
    property real telemetryAngle: 2 * Math.PI / 3
    property real sysInfoAngle: 4 * Math.PI / 3
    property real musicAngle: Math.PI
    property real trayAngle: Math.PI * 1.5

    property real gaugeBaseY: 0.15
    property real weatherRingPhaseOffset: 0
    property real gaugeRepositionOffset: 0

    Timer {
        id: globalEngine
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            if (!sceneMouse.pressed) {
                root.targetCamY -= 0.00004;
                root.targetRotY += 0.0003;
            }

            root.camX += (root.targetCamX - root.camX) * 0.12;
            root.camY += (root.targetCamY - root.camY) * 0.12;
            root.rotX += (root.targetRotX - root.rotX) * 0.12;
            root.rotY += (root.targetRotY - root.rotY) * 0.12;

            let now = new Date();
            let utcHrs = now.getUTCHours() + now.getUTCMinutes() / 60 + now.getUTCSeconds() / 3600;
            let dayOfYear = Math.floor((now - new Date(now.getFullYear(), 0, 0)) / 86400000);

            let solDecl = 23.44 * Math.sin((2 * Math.PI * (dayOfYear - 80)) / 365.25);
            let solLat = solDecl * Math.PI / 180;
            let solLong = (0.5 - utcHrs / 24) * 2 * Math.PI;

            let sX = Math.cos(solLat) * Math.sin(solLong);
            let sY = Math.sin(solLat);
            let sZ = Math.cos(solLat) * Math.cos(solLong);

            let sY_cam = sY * root.cosCx - sZ * root.sinCx;
            let sZ_pos = sY * root.sinCx + sZ * root.cosCx;
            root.sunValueX = sX * root.cosCy + sZ_pos * root.sinCy;
            root.sunValueY = sY_cam;

            root.earthAutoRotation = ((utcHrs / 24) * 2 * Math.PI - root.camY) % (Math.PI * 2);
            root.independentCometAngle = (root.independentCometAngle + 0.002) % (Math.PI * 2);

            let baseSpeed = 0.0012;
            let getFactor = (z) => {
                if (z < -0.5) return 3.0;
                if (z < 0) return 2.0;
                if (z > 1.0) return 0.3;
                if (z > 0.7) return 0.5;
                return 0.8;
            };

            let twoPi = Math.PI * 2;
            let g = gaugeSatellite.proj.z;
            let t = telemetrySatellite.proj.z;
            let s = sysInfoSatellite.proj.z;
            let m = musicSatellite.proj.z;
            let tr = traySatellite.proj.z;
            let e = easterEggSatellite.proj.z;

            root.gaugeAngle     = (root.gaugeAngle      + (baseSpeed * 0.4) * getFactor(g))  % twoPi;
            root.telemetryAngle = (root.telemetryAngle + baseSpeed * getFactor(t))  % twoPi;
            root.sysInfoAngle   = (root.sysInfoAngle   + baseSpeed * getFactor(s))  % twoPi;
            root.musicAngle     = (root.musicAngle      + baseSpeed * getFactor(m))  % twoPi;
            root.trayAngle      = (root.trayAngle      + baseSpeed * getFactor(tr)) % twoPi;
            root.easterEggAngle = (root.easterEggAngle + baseSpeed * getFactor(e))  % twoPi;
        }
    }

    function project3D(bx, by, bz, isSatellite) {
        let x = bx;
        let y = by;
        let z = bz;

        if (isSatellite) {
            let y1 = y * root.cosRx + z * root.sinRx;
            let z1 = -y * root.sinRx + z * root.cosRx;
            x = x * root.cosRy - z1 * root.sinRy;
            y = y1;
            z = bx * root.sinRy + z1 * root.cosRy;
        }

        let y2 = y * root.cosCx - z * root.sinCx;
        let z2 = y * root.sinCx + z * root.cosCx;
        let x3 = x * root.cosCy + z2 * root.sinCy;
        let z3 = -x * root.sinCy + z2 * root.cosCy;

        return { x: x3, y: y2, z: z3 };
    }

    function repositionWeatherRing() {
        let satAngles = [
            root.gaugeAngle + root.gaugeRepositionOffset,
            root.telemetryAngle,
            root.sysInfoAngle,
            root.musicAngle,
            root.trayAngle,
            root.easterEggAngle
        ];

        const numNodes = 8;
        const spacing = 2 * Math.PI / numNodes;
        let bestOffset = 0;
        let bestMinDist = -1;

        for (let i = 0; i < 200; i++) {
            let offset = (i / 200) * 2 * Math.PI;
            let minDist = Infinity;
            for (let j = 0; j < numNodes; j++) {
                let nodeAngle = (j * spacing + root.independentCometAngle + offset) % (2 * Math.PI);
                for (let k = 0; k < satAngles.length; k++) {
                    let diff = Math.abs(nodeAngle - satAngles[k]);
                    diff = Math.min(diff, 2 * Math.PI - diff);
                    if (diff < minDist) minDist = diff;
                }
            }
            if (minDist > bestMinDist) {
                bestMinDist = minDist;
                bestOffset = offset;
            }
        }

        root.weatherRingPhaseOffset = bestOffset;
    }

    function repositionGaugeSatellite() {
        const numNodes = 8;
        const spacing = 2 * Math.PI / numNodes;
        let nodes = [];
        for (let i = 0; i < numNodes; i++) {
            nodes.push((i * spacing + root.independentCometAngle + root.weatherRingPhaseOffset) % (2 * Math.PI));
        }
        nodes.sort((a, b) => a - b);

        let maxGap = 0;
        let gapMid = 0;
        for (let i = 0; i < nodes.length; i++) {
            let next = (i + 1) % nodes.length;
            let gap = (nodes[next] - nodes[i] + 2 * Math.PI) % (2 * Math.PI);
            if (gap > maxGap) {
                maxGap = gap;
                gapMid = (nodes[i] + gap / 2) % (2 * Math.PI);
            }
        }

        root.gaugeRepositionOffset = (gapMid - root.gaugeAngle + 2 * Math.PI) % (2 * Math.PI);
        root.gaugeBaseY = 0.35;
    }

    onWeatherRingsActiveChanged: {
        if (weatherRingsActive) {
            repositionWeatherRing();
            repositionGaugeSatellite();
        } else {
            gaugeBaseY = 0.15;
            gaugeRepositionOffset = 0;
        }
    }

    Rectangle {
        id: windowContent
        anchors.fill: parent
        color: "transparent"
        clip: true

        opacity: 0.0
        scale: 0.97

        Component.onCompleted: entranceAnimation.start()

        ParallelAnimation {
            id: entranceAnimation
            NumberAnimation { target: windowContent; property: "opacity"; to: 1.0; duration: 500; easing.type: Easing.OutExpo }
            NumberAnimation { target: windowContent; property: "scale";   to: 1.0; duration: 600; easing.type: Easing.OutExpo }
        }

        PinchArea {
            id: scenePinch
            anchors.fill: parent
            z: -105000
            property real pinchStartZoom: 1.0
            onPinchStarted: pinchStartZoom = root.zoomFactor
            onPinchUpdated: pinch => {
                root.zoomFactor = Math.max(0.25, Math.min(3.0, pinchStartZoom * pinch.scale));
            }

            MouseArea {
                id: sceneMouse
                anchors.fill: parent
                hoverEnabled: true
                property real lastX: 0
                property real lastY: 0
                property real mouseShiftX: 0
                property real mouseShiftY: 0

                onPositionChanged: mouse => {
                    mouseShiftX = (mouse.x - root.width / 2) / (root.width / 2);
                    mouseShiftY = (mouse.y - root.height / 2) / (root.height / 2);
                    if (!pressed) return;
                    let dx = mouse.x - lastX;
                    let dy = mouse.y - lastY;

                    if (mouse.modifiers & Qt.ControlModifier) {
                        root.targetCamY -= dx * 0.0012;
                        let newCamX = root.targetCamX + dy * 0.0012;
                        root.targetCamX = Math.max(-1.45, Math.min(1.45, newCamX));
                    } else {
                        root.targetRotY += dx * 0.005;
                        let newRotX = root.targetRotX - dy * 0.005;
                        root.targetRotX = Math.max(-1.45, Math.min(1.45, newRotX));
                    }
                    lastX = mouse.x;
                    lastY = mouse.y;
                }
                onWheel: wheel => {
                    if (wheel.modifiers & Qt.ControlModifier) {
                        let zoomDelta = wheel.angleDelta.y > 0 ? 0.06 : -0.06;
                        root.zoomFactor = Math.max(0.25, Math.min(3.0, root.zoomFactor + zoomDelta));
                        wheel.accepted = true;
                    }
                }
            }
        }

        Item {
            x: earthSystem.x
            y: earthSystem.y
            width: earthSystem.width
            height: earthSystem.height
            z: -99999

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.35)
                border.width: 14 * root.zoomFactor
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -18 * root.zoomFactor
                radius: width / 2
                color: "transparent"
                border.color: Qt.rgba(root.sapphire.r, root.sapphire.g, root.sapphire.b, 0.18)
                border.width: 25 * root.zoomFactor
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -45 * root.zoomFactor
                radius: width / 2
                color: "transparent"
                border.color: Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.08)
                border.width: 45 * root.zoomFactor
            }
        }

        Shape {
            id: orbitCurvePath
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4
            opacity: 0.35
            z: -50000

            ShapePath {
                strokeColor: root.blue
                strokeWidth: 1.2 * root.zoomFactor
                strokeStyle: ShapePath.DashLine
                dashPattern: [6, 8]
                fillColor: "transparent"

                startX: root.width / 2 - (380 * root.zoomFactor)
                startY: root.height / 2 + (120 * root.zoomFactor)

                PathArc {
                    x: root.width / 2 - (380 * root.zoomFactor)
                    y: root.height / 2 + (120 * root.zoomFactor)
                    radiusX: 380 * root.zoomFactor
                    radiusY: 180 * root.zoomFactor
                    useLargeArc: false
                    direction: PathArc.Clockwise
                }
            }
        }

        EarthSystem {
            id: earthSystem
            anchors.fill: parent
            earthProj: root.project3D(0.2, 1.2, root.earthZOffset, false)
            earthZoom: root.earthZoom
            mouseShiftX: sceneMouse.mouseShiftX
            mouseShiftY: sceneMouse.mouseShiftY
            weatherIcon: root.weatherIcon
            weatherTemp: root.weatherTemp
            weatherHex: root.weatherHex
            weatherRingsActive: root.weatherRingsActive
            timeStr: root.timeStr
            fullDateStr: root.fullDateStr
            sunValueX: root.sunValueX
            sunValueY: root.sunValueY
            screenSunAngleDeg: root.screenSunAngleDeg
            detailedWeatherData: root.detailedWeatherData
            independentCometAngle: root.independentCometAngle
            weatherRingPhaseOffset: root.weatherRingPhaseOffset
            baseSphereRadius: root.baseSphereRadius
            earthSphereRadius: root.earthSphereRadius
            satelliteZoom: root.satelliteZoom
            scenePressed: sceneMouse.pressed
            project3DFunc: (bx, by, bz, flag) => root.project3D(bx, by, bz, flag)
            onToggleWeatherRequested: root.weatherRingsActive = !root.weatherRingsActive
        }

        GaugeSatellite {
            id: gaugeSatellite
            angle: root.gaugeAngle + root.gaugeRepositionOffset
            gaugeBaseY: root.gaugeBaseY
            proj: root.project3D(Math.cos(angle) * orbitDistance, gaugeBaseY + Math.sin(angle) * 0.10, Math.sin(angle) * orbitDistance, true)
            originX: (windowContent.width / 2) + (earthSystem.earthProj.x * root.baseSphereRadius)
            originY: (windowContent.height / 2) + (earthSystem.earthProj.y * root.baseSphereRadius)
            earthSphereRadius: root.earthSphereRadius
            satelliteZoom: root.satelliteZoom
            isSearchMode: root.isSearchMode
            weatherRingsActive: root.weatherRingsActive
            pressed: sceneMouse.pressed
            independentCometAngle: root.independentCometAngle
            detailedWeatherData: root.detailedWeatherData
        }

        Item {
            id: worldCenter
            width:  root.sphereRadius * 2
            height: root.sphereRadius * 2
            z: 1000
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2

            MoonSphere {
                rotX: root.rotX
                rotY: root.rotY
                camX: root.camX
                camY: root.camY
                sunValueX: root.sunValueX
                sunValueY: root.sunValueY
            }

            TelemetrySatellite {
                id: telemetrySatellite
                angle: root.telemetryAngle
                proj: root.project3D(Math.cos(angle) * orbitDistance, Math.sin(angle) * 0.08, Math.sin(angle) * orbitDistance, true)
                sphereRadius: root.sphereRadius
                satelliteZoom: root.satelliteZoom
                isSearchMode: root.isSearchMode
                pressed: sceneMouse.pressed
                centerWidth: worldCenter.width
                centerHeight: worldCenter.height
                independentCometAngle: root.independentCometAngle
            }

            SysInfoSatellite {
                id: sysInfoSatellite
                angle: root.sysInfoAngle
                proj: root.project3D(Math.cos(angle) * orbitDistance, 0.42 + Math.cos(angle * 2.1 + 3.0) * 0.05, Math.sin(angle) * orbitDistance, true)
                sphereRadius: root.sphereRadius
                satelliteZoom: root.satelliteZoom
                isSearchMode: root.isSearchMode
                pressed: sceneMouse.pressed
                centerWidth: worldCenter.width
                centerHeight: worldCenter.height
                independentCometAngle: root.independentCometAngle
                kbLayout: pollers.kbLayout
                volIcon: pollers.volIcon
                volPercent: pollers.volPercent
                isSoundActive: pollers.isSoundActive
                showEthernet: pollers.showEthernet
                ethStatus: pollers.ethStatus
                isWifiOn: pollers.isWifiOn
                wifiIcon: pollers.wifiIcon
                wifiSsid: pollers.wifiSsid
                isBtOn: pollers.isBtOn
                btIcon: pollers.btIcon
                btDevice: pollers.btDevice
                isDesktop: pollers.isDesktop
                batColor: pollers.batColor
                batIcon: pollers.batIcon
                batPercent: pollers.batPercent
            }

            MusicSatellite {
                id: musicSatellite
                angle: root.musicAngle
                proj: root.project3D(Math.cos(angle) * orbitDistance, -0.05 + Math.sin(angle * 2.5 + 4.0) * 0.045, Math.sin(angle) * orbitDistance, true)
                sphereRadius: root.sphereRadius
                satelliteZoom: root.satelliteZoom
                isSearchMode: root.isSearchMode
                pressed: sceneMouse.pressed
                centerWidth: worldCenter.width
                centerHeight: worldCenter.height
                independentCometAngle: root.independentCometAngle
            }

            EasterEggSatellite {
                id: easterEggSatellite
                angle: root.easterEggAngle
                proj: root.project3D(Math.cos(angle) * orbitDistance, 0.12 + Math.cos(angle * 3.0 + 2.0) * 0.04, Math.sin(angle) * orbitDistance, true)
                sphereRadius: root.sphereRadius
                satelliteZoom: root.satelliteZoom
                isSearchMode: root.isSearchMode
                pressed: sceneMouse.pressed
                centerWidth: worldCenter.width
                centerHeight: worldCenter.height
                independentCometAngle: root.independentCometAngle
            }

            TraySatellite {
                id: traySatellite
                angle: root.trayAngle
                proj: root.project3D(Math.cos(angle) * orbitDistance, -0.30 + Math.sin(angle * 2.2 + 5.0) * 0.06, Math.sin(angle) * orbitDistance, true)
                sphereRadius: root.sphereRadius
                satelliteZoom: root.satelliteZoom
                isSearchMode: root.isSearchMode
                pressed: sceneMouse.pressed
                centerWidth: worldCenter.width
                centerHeight: worldCenter.height
                independentCometAngle: root.independentCometAngle
                parentWindow: root
            }
        }
    }
}
