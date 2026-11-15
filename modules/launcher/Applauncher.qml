import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "."
import "../../theme"
import "../../services"

Item {
    id: window

    signal closeRequested()
    property alias searchInput: searchContainer.searchInput
    focus: true

    implicitWidth: Screen.width
    implicitHeight: Screen.height

    Caching { id: paths }

    Scaler {
        id: scaler
        currentWidth: window.width
    }

    function s(val) {
        let res = scaler.s(val);
        return res > 0 ? res : val;
    }

    MatugenColors { id: _theme }

    readonly property color base:      _theme.base
    readonly property color mantle:    _theme.mantle    || _theme.base
    readonly property color crust:     _theme.crust
    readonly property color surface0:  _theme.surface0
    readonly property color surface1:  _theme.surface1
    readonly property color surface2:  _theme.surface2
    readonly property color text:      _theme.text
    readonly property color subtext0:  _theme.subtext0
    readonly property color blue:      _theme.blue      || "#89b4fa"
    readonly property color mauve:     _theme.mauve     || "#cba6f7"
    readonly property color teal:      _theme.teal      || "#94e2d5"
    readonly property color overlay0:  _theme.overlay0  || "#6c7086"
    readonly property color peach:     _theme.peach     || "#fab387"
    readonly property color yellow:    _theme.yellow    || "#f9e2af"
    readonly property color sapphire:  _theme.sapphire  || "#74c7ec"

    readonly property real _s2:   window.s(2)
    readonly property real _s3:   window.s(3)
    readonly property real _s4:   window.s(4)
    readonly property real _s5:   window.s(5)
    readonly property real _s8:   window.s(8)
    readonly property real _s11:  window.s(11)
    readonly property real _s12:  window.s(12)
    readonly property real _s15:  window.s(15)
    readonly property real _s16:  window.s(16)
    readonly property real _s18:  window.s(18)
    readonly property real _s20:  window.s(20)
    readonly property real _s28:  window.s(28)
    readonly property real _s40:  window.s(40)
    readonly property real _s50:  window.s(50)
    readonly property real _s55:  window.s(55)
    readonly property real _s56:  window.s(56)
    readonly property real _s63:  window.s(63)
    readonly property real _s74:  window.s(74)
    readonly property real _s104: window.s(104)

    // Satellite-specific original full-scale dimensions
    readonly property real _sat_hullW:     window.s(270)
    readonly property real _sat_hullH:     window.s(185)
    readonly property real _sat_panelW:    window.s(80)
    readonly property real _sat_panelH:    window.s(64)
    readonly property real _sat_strutW:    window.s(12)
    readonly property real _sat_strutH:    window.s(5)
    readonly property real _sat_antennaH:  window.s(20)
    readonly property real _sat_thrusterH: window.s(14)
    readonly property real _sat_radius12:  window.s(12)
    readonly property real _sat_radius8:   window.s(8)
    readonly property real _sat_radius4:   window.s(4)
    readonly property real _sat_antBall:   window.s(8)
    readonly property real _sat_antStick:  window.s(3)
    readonly property real _sat_antOffX:   window.s(18)
    readonly property real _sat_screenM:   window.s(10)
    readonly property real _sat_innerM:    window.s(12)
    readonly property real _sat_iconSz:    window.s(52)
    readonly property real _sat_fontSize:  window.s(12)
    readonly property real _sat_thrBase:   window.s(20)
    readonly property real _sat_spacing:   window.s(6)

    property real baseSphereRadius: 265
    property real sphereZoom: 1.0
    Behavior on sphereZoom { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    property real sphereRadius: baseSphereRadius

    property real rotX: -0.2
    property real rotY: 0

    NumberAnimation { id: searchRotXAnim; target: window; property: "rotX"; duration: 700; easing.type: Easing.OutCubic }
    NumberAnimation { id: searchRotYAnim; target: window; property: "rotY"; duration: 700; easing.type: Easing.OutCubic }

    property var projCache: []
    property bool projDirty: true

    function rebuildProjCache() {
        if (!projDirty) return;
        projDirty = false;

        let phi   = Math.PI * (3 - Math.sqrt(5));
        let total = appModel.count;
        let rx    = window.rotX;
        let ry    = window.rotY;
        let cosRx = Math.cos(rx), sinRx = Math.sin(rx);
        let cosRy = Math.cos(ry), sinRy = Math.sin(ry);

        let arr = new Array(total);
        for (let i = 0; i < total; i++) {
            let b_y      = 1.0 - (i / Math.max(1, total - 1)) * 2.0;
            let b_radius = Math.sqrt(1.0 - b_y * b_y);
            let b_theta  = phi * i;
            let b_x      = Math.cos(b_theta) * b_radius;
            let b_z      = Math.sin(b_theta) * b_radius;

            // Rotate Y (longitude)
            let x1 = b_x * cosRy + b_z * sinRy;
            let z1 = -b_x * sinRy + b_z * cosRy;

            // Rotate X (latitude tilt)
            let y2 = b_y * cosRx - z1 * sinRx;
            let z2 = b_y * sinRx + z1 * cosRx;

            arr[i] = { x: x1, y: y2, z: z2 };
        }
        window.projCache = arr;
    }

    // Invalidate cache whenever rotation changes
    onRotXChanged: { projDirty = true; rebuildProjCache(); }
    onRotYChanged: { projDirty = true; rebuildProjCache(); }

    function project3D(bx, by, bz) {
        let rx = window.rotX;
        let ry = window.rotY;
        let cosRx = Math.cos(rx), sinRx = Math.sin(rx);
        let cosRy = Math.cos(ry), sinRy = Math.sin(ry);
        let x1 = bx * cosRy + bz * sinRy;
        let z1 = -bx * sinRy + bz * cosRy;
        let y2 = by * cosRx - z1 * sinRx;
        let z2 = by * sinRx + z1 * cosRx;
        return { x: x1, y: y2, z: z2 };
    }

    Timer {
        interval: 16
        running: !sceneMouse.pressed && !searchRotXAnim.running && !searchRotYAnim.running
        repeat: true
        onTriggered: window.rotY -= 0.002
    }

    function centerOnApp(index) {
        if (index < 0 || index >= appModel.count) return;

        let phi      = Math.PI * (3 - Math.sqrt(5));
        let total    = appModel.count;
        let b_y      = 1.0 - (index / Math.max(1, total - 1)) * 2.0;
        let b_radius = Math.sqrt(1.0 - b_y * b_y);
        let b_theta  = phi * index;
        let b_x      = Math.cos(b_theta) * b_radius;
        let b_z      = Math.sin(b_theta) * b_radius;

        // Longitude: rotate Y around vertical axis to bring point to front meridian (x1 = 0, z1 >= 0)
        let targetRotY = -Math.atan2(b_x, b_z);
        let z1         = Math.sqrt(b_x * b_x + b_z * b_z);

        // Latitude: rotate X around horizontal axis to bring point to center (y2 = 0, z2 = 1.0)
        let targetRotX = Math.atan2(b_y, z1);

        let currentRotYMod = ((window.rotY % (Math.PI * 2)) + Math.PI * 2) % (Math.PI * 2);
        let targetRotYNorm = ((targetRotY % (Math.PI * 2)) + Math.PI * 2) % (Math.PI * 2);

        let diff = targetRotYNorm - currentRotYMod;
        if (diff >  Math.PI) diff -= Math.PI * 2;
        if (diff < -Math.PI) diff += Math.PI * 2;

        searchRotXAnim.to = Math.max(-1.45, Math.min(1.45, targetRotX));
        searchRotYAnim.to = window.rotY + diff;

        searchRotXAnim.restart();
        searchRotYAnim.restart();
    }

    property bool isOpen: false
    property real introPhase: 0.0

    NumberAnimation {
        id: openAnim
        target: window
        property: "introPhase"
        from: 0.0
        to: 1.0
        duration: 520
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation {
            target: window
            property: "introPhase"
            to: 0.0
            duration: 380
            easing.type: Easing.InOutCubic
        }
        ScriptAction {
            script: window.closeRequested()
        }
    }

    function openLauncher() {
        closeAnim.stop();
        window.introPhase = 0.0;
        window.isOpen = true;
        searchContainer.text = "";
        window.searchQuery = "";
        window.selectedAppIndex = -1;
        selectedSatelliteContainer.satScale = 0.0;
        selectedSatelliteContainer.satOpacity = 0.0;
        selectedSatelliteContainer.satAnimOffsetY = 40;
        selectedSatelliteContainer.satPanelDeploy = 0.0;
        window.sphereZoom = 1.0;
        searchContainer.forceActiveFocus();
        openAnim.restart();
    }

    function closeLauncher() {
        if (!window.isOpen && !openAnim.running) return;
        window.isOpen = false;
        selectedSatelliteContainer.triggerExit();
        openAnim.stop();
        closeAnim.restart();
    }

    Connections {
        target: window
        function onVisibleChanged() {
            if (window.visible && !window.isOpen) {
                window.openLauncher();
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: window.closeLauncher()
    }

    property var    allApps: []
    property string searchQuery: ""
    property int    selectedAppIndex: -1

    onSelectedAppIndexChanged: {
        if (window.selectedAppIndex >= 0) {
            selectedSatelliteContainer.triggerEntrance();
        } else {
            selectedSatelliteContainer.triggerExit();
        }
    }

    property string selectedAppName: ""
    property string selectedAppIcon: ""
    property string selectedAppExec: ""

    Process {
        id: appFetcher
        running: true
        command: [paths.qsDir + "/services/galaxy3d-helper", "apps"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0) {
                        window.allApps = JSON.parse(this.text);
                        // Batch-append in chunks to avoid a single long block on
                        // the main thread that freezes the intro animation.
                        let apps  = window.allApps;
                        let chunk = 40;
                        let idx   = 0;
                        function appendChunk() {
                            let end = Math.min(idx + chunk, apps.length);
                            for (; idx < end; idx++) appModel.append(apps[idx]);
                            if (idx < apps.length) Qt.callLater(appendChunk);
                            else { window.projDirty = true; window.rebuildProjCache(); }
                        }
                        appendChunk();
                    }
                } catch(e) { console.log(e); }
            }
        }
    }

    ListModel { id: appModel }

    function handleSearch(query) {
        window.searchQuery = query.toLowerCase().trim();
        if (window.searchQuery === "") {
            window.selectedAppIndex = -1;
            window.selectedAppName  = "";
            window.selectedAppIcon  = "";
            window.selectedAppExec  = "";
            window.sphereZoom       = 1.0;
            return;
        }
        let found = false;
        // Priority 1: Exact match or starts with query, or matches exec binary
        for (let i = 0; i < appModel.count; i++) {
            let name = appModel.get(i).name.toLowerCase();
            let execCmd = (appModel.get(i).exec || "").toLowerCase();
            if (name === window.searchQuery || name.startsWith(window.searchQuery) || execCmd.includes(window.searchQuery)) {
                if (window.selectedAppIndex !== i) {
                    window.selectedAppName  = appModel.get(i).name;
                    window.selectedAppIcon  = appModel.get(i).icon || "";
                    window.selectedAppExec  = appModel.get(i).exec || "";
                    centerOnApp(i);
                    window.sphereZoom = 1.65;
                    window.selectedAppIndex = i;
                }
                found = true;
                break;
            }
        }
        // Priority 2: Substring match in application name
        if (!found) {
            for (let i = 0; i < appModel.count; i++) {
                if (appModel.get(i).name.toLowerCase().includes(window.searchQuery)) {
                    if (window.selectedAppIndex !== i) {
                        window.selectedAppName  = appModel.get(i).name;
                        window.selectedAppIcon  = appModel.get(i).icon || "";
                        window.selectedAppExec  = appModel.get(i).exec || "";
                        centerOnApp(i);
                        window.sphereZoom = 1.65;
                        window.selectedAppIndex = i;
                    }
                    found = true;
                    break;
                }
            }
        }
        if (!found) {
            window.selectedAppIndex = -1;
            window.sphereZoom       = 1.0;
        }
    }

    function launchApp(appName, execStr) {
        if (!execStr) return;
        let cleanCmd = execStr.replace(/%[fFuUdDnNickvm]/g, "").trim();
        Hyprland.dispatch("exec " + cleanCmd);
        window.closeLauncher();
    }
    Item {
        anchors.fill: parent
        opacity: window.introPhase

        Repeater {
            model: 50
            Rectangle {
                property real seed: Math.random()
                x: seed * window.width
                y: Math.random() * window.height
                width:  window._s2 + Math.random() * window._s2
                height: width
                radius: width / 2
                color:  window.text
                opacity: 0.08 + Math.random() * 0.12
            }
        }
    }

    Item {
        id: scene3D
        anchors.fill: parent
        opacity: window.introPhase
        // No scale on root container to prevent shifting origin from moon center
        transformOrigin: Item.Center

        MouseArea {
            id: sceneMouse
            anchors.fill: parent
            property real lastX: 0
            property real lastY: 0
            onPressed: mouse => {
                searchRotXAnim.stop();
                searchRotYAnim.stop();
                lastX = mouse.x;
                lastY = mouse.y;
            }
            onPositionChanged: mouse => {
                if (!pressed) return;
                let dx = mouse.x - lastX;
                let dy = mouse.y - lastY;
                window.rotY += dx * 0.005;
                let newRotX = window.rotX - dy * 0.005;
                window.rotX = Math.max(-1.45, Math.min(1.45, newRotX));
                lastX = mouse.x;
                lastY = mouse.y;
            }
            onClicked: searchContainer.forceActiveFocus()
        }

        Item {
            id: origin
            anchors.centerIn: parent
            width:  window.baseSphereRadius * 2
            height: window.baseSphereRadius * 2
            transformOrigin: Item.Center
            scale: 0.68 + (0.32 * window.introPhase)
            opacity: Math.max(0.0, Math.min(1.0, window.introPhase * 1.25))

            Repeater {
                id: appRepeater
                model: appModel

                delegate: AppCard {
                    proj: (window.projCache && window.projCache.length > index)
                          ? window.projCache[index]
                          : { x: 0, y: 0, z: 0 }
                    sphereRadius: window.sphereRadius
                    sphereZoom: window.sphereZoom
                    searchQuery: window.searchQuery
                    isSelected: index === window.selectedAppIndex
                    appName: model.name
                    appIcon: model.icon || ""
                    appExec: model.exec || ""
                    selectedAppName: window.selectedAppName
                    selectedAppIcon: window.selectedAppIcon

                    onLaunchRequested: (name, exec) => window.launchApp(name, exec)
                }
            }
        }

        // Dedicated search result satellite pinned horizontally over the Moon center
        Item {
            id: selectedSatelliteContainer
            anchors.centerIn: parent
            anchors.verticalCenterOffset: satAnimOffsetY
            width: satItem.satW
            height: satItem.satH
            z: 1100
            transformOrigin: Item.Center

            property real satScale: 0.0
            property real satOpacity: 0.0
            property real satAnimOffsetY: 40
            property real satPanelDeploy: 0.0

            scale: satScale
            opacity: satOpacity * Math.min(1.0, window.introPhase * 1.5)
            visible: opacity > 0.005

            function triggerEntrance() {
                satExitAnim.stop();
                satEntranceAnim.stop();
                satScale = 0.25;
                satOpacity = 0.0;
                satAnimOffsetY = 38;
                satPanelDeploy = 0.0;
                satEntranceAnim.restart();
            }

            function triggerExit() {
                satEntranceAnim.stop();
                satExitAnim.stop();
                satExitAnim.restart();
            }

            ParallelAnimation {
                id: satEntranceAnim

                NumberAnimation {
                    target: selectedSatelliteContainer
                    property: "satScale"
                    from: 0.30
                    to: 1.25
                    duration: 440
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.35
                }

                NumberAnimation {
                    target: selectedSatelliteContainer
                    property: "satOpacity"
                    from: 0.0
                    to: 1.0
                    duration: 320
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: selectedSatelliteContainer
                    property: "satAnimOffsetY"
                    from: 38
                    to: 0
                    duration: 440
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.15
                }

                NumberAnimation {
                    target: selectedSatelliteContainer
                    property: "satPanelDeploy"
                    from: 0.0
                    to: 1.0
                    duration: 520
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.25
                }
            }

            ParallelAnimation {
                id: satExitAnim

                NumberAnimation {
                    target: selectedSatelliteContainer
                    property: "satScale"
                    to: 0.55
                    duration: 250
                    easing.type: Easing.InCubic
                }

                NumberAnimation {
                    target: selectedSatelliteContainer
                    property: "satOpacity"
                    to: 0.0
                    duration: 220
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: selectedSatelliteContainer
                    property: "satAnimOffsetY"
                    to: -25
                    duration: 250
                    easing.type: Easing.InCubic
                }

                NumberAnimation {
                    target: selectedSatelliteContainer
                    property: "satPanelDeploy"
                    to: 0.0
                    duration: 220
                    easing.type: Easing.InCubic
                }
            }

            SatelliteItem {
                id: satItem
                anchors.centerIn: parent
                appName: window.selectedAppName
                appIcon: window.selectedAppIcon
                panelDeploy: selectedSatelliteContainer.satPanelDeploy
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: window.launchApp(window.selectedAppName, window.selectedAppExec)
            }
        }

        // Damaged satellite displayed over the Moon when search yields no matches
        Item {
            id: emptySearchContainer
            anchors.centerIn: parent
            width: damagedSat.satW
            height: damagedSat.satH
            z: 1100
            transformOrigin: Item.Center

            property bool showEmpty: window.searchQuery !== "" && window.selectedAppIndex === -1 && window.introPhase > 0.1

            opacity: showEmpty ? 1.0 : 0.0
            scale: showEmpty ? 1.25 : 0.70
            visible: opacity > 0.005

            Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 380; easing.type: Easing.OutBack  } }

            DamagedSatelliteItem {
                id: damagedSat
                anchors.centerIn: parent
                searchQuery: window.searchQuery
            }
        }
    }

    SearchBox {
        id: searchContainer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: window._s63
        anchors.horizontalCenter: parent.horizontalCenter
        introPhase: window.introPhase

        onSearchModified: query => window.handleSearch(query)

        onDownPressed: {
            for (let i = window.selectedAppIndex + 1; i < appModel.count; i++) {
                if (appModel.get(i).name.toLowerCase().includes(window.searchQuery)) {
                    window.selectedAppIndex = i;
                    window.selectedAppName  = appModel.get(i).name;
                    window.selectedAppIcon  = appModel.get(i).icon || "";
                    window.selectedAppExec  = appModel.get(i).exec || "";
                    window.centerOnApp(i);
                    window.sphereZoom = 1.65;
                    break;
                }
            }
        }

        onUpPressed: {
            for (let i = window.selectedAppIndex - 1; i >= 0; i--) {
                if (appModel.get(i).name.toLowerCase().includes(window.searchQuery)) {
                    window.selectedAppIndex = i;
                    window.selectedAppName  = appModel.get(i).name;
                    window.selectedAppIcon  = appModel.get(i).icon || "";
                    window.selectedAppExec  = appModel.get(i).exec || "";
                    window.centerOnApp(i);
                    window.sphereZoom = 1.65;
                    break;
                }
            }
        }

        onReturnPressed: {
            if (window.selectedAppIndex >= 0 && window.selectedAppIndex < appModel.count) {
                window.launchApp(
                    appModel.get(window.selectedAppIndex).name,
                    appModel.get(window.selectedAppIndex).exec
                );
            }
        }

        onEscapePressed: window.closeLauncher()
    }
}
