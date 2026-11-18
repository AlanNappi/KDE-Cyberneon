// CyberNeon Biomonitor - top-left HUD status block for Plasma 6 (X11 and Wayland). Original artwork.
// Real system data in a game-HUD layout: level badge = uptime hours, segmented "integrity" bar = free memory,
// unit blocks = free CPU, thin bar = storage, network rates, operator name; on laptops a CELL CHARGE gauge.
// It reacts to the system: over the load limits the frame pulses red and the status line reports the overload.
// With the TUXEDO Control Center running, the status line shows its active profile (nothing otherwise).
// It also hosts the Quickhack OSD and triggers the optional sound effects.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.plasma5support as P5Support
import "cnconfig.js" as Cfg

PlasmoidItem {
    id: root

    readonly property string label: "@HUD_LABEL@"          // replaced by install.sh (HUD_LABEL)
    readonly property color cy: "#5beedc"
    readonly property color red: "#ff2a4f"
    readonly property color navy: "#0b1620"

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Sensors.Sensor { id: cpu;    sensorId: "cpu/all/usage";               updateRateLimit: 1000 }
    Sensors.Sensor { id: memUsed; sensorId: "memory/physical/used";       updateRateLimit: 2000 }
    Sensors.Sensor { id: memTot; sensorId: "memory/physical/total";       updateRateLimit: 60000 }
    Sensors.Sensor { id: disk;   sensorId: "disk/all/usedPercent";        updateRateLimit: 10000 }
    Sensors.Sensor { id: down;   sensorId: "network/all/download";        updateRateLimit: 1000 }
    Sensors.Sensor { id: up;     sensorId: "network/all/upload";          updateRateLimit: 1000 }
    Sensors.Sensor { id: uptime; sensorId: "os/system/uptime";            updateRateLimit: 60000 }

    readonly property real totalMB: Math.max(1, (Number(memTot.value) || 0) / 1048576)
    readonly property real freeMB: Math.max(0, totalMB - (Number(memUsed.value) || 0) / 1048576)   // cache counts as free
    readonly property real integrity: Math.max(0, Math.min(1, freeMB / totalMB))
    readonly property real cpuFree: 1 - Math.max(0, Math.min(100, Number(cpu.value) || 0)) / 100

    readonly property color accent: reactor.alert ? red : cy
    property string tccProfile: ""
    property int seq: 0

    CyberNeonReactor { id: reactor; onAlertChanged: root.alertChanged() }
    CyberNeonPower { id: power }
    Loader { id: quickhack; source: "QuickhackOsd.qml" }       // separate: a problem there must not take the HUD down
    Connections { target: quickhack.item; function onNotified() { root.sfx("message-new-instant") } }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            if (source.indexOf("cn-tcc") >= 0) root.readTcc(data.stdout || "");
        }
    }
    function run(tool, args) { exec.connectSource('"$HOME/.local/share/cyberneon/bin/' + tool + '" ' + args + ' #' + (++seq)) }
    function sfx(name) { if (Cfg.SOUND_FX) run("cn-sfx", name) }
    function alertChanged() {
        run("cn-kwin-alert", reactor.alert ? "true" : "false");
        if (reactor.alert) sfx("dialog-warning");
    }
    function readTcc(out) {
        try { tccProfile = String(JSON.parse(JSON.parse(out).data[0]).name || "").toUpperCase() }
        catch (e) { tccProfile = "" }
    }
    Timer { interval: 60000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.run("cn-tcc", "") }
    Component.onCompleted: run("cn-kwin-alert", "false")     // clears a state left by a previous session

    readonly property string statusText: reactor.alert ? "!! OVERLOAD  //  " + reactor.reason
                                       : power.lowPower ? "LOW POWER  //  ANIMATION OFF"
                                       : tccProfile ? "TCC  //  " + tccProfile
                                       : "LINK STABLE  //  ID 0x" + (label.length * 4097 + 2077).toString(16).toUpperCase()

    function rate(b) {
        b = Number(b) || 0
        if (b > 1048576) return (b / 1048576).toFixed(1) + "M"
        if (b > 1024) return (b / 1024).toFixed(0) + "K"
        return b.toFixed(0) + "B"
    }
    function grouped(n) { return Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ") }

    fullRepresentation: Item {
        // compact: it must end above the terminal drawn in the wallpaper (top-left)
        implicitWidth: 560
        implicitHeight: 104

        Item {
            id: hud
            anchors.fill: parent
            anchors.margins: 6
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: root.accent; shadowBlur: 0.6; blurMax: 16
                                        shadowOpacity: 0.6; shadowHorizontalOffset: 0; shadowVerticalOffset: 0; autoPaddingEnabled: true }

            // alert frame: pulses while the system is overloaded
            Shape {
                x: -4; y: -4; width: parent.width + 8; height: parent.height + 6   // stops above the wallpaper's terminal
                visible: reactor.alert
                preferredRendererType: Shape.CurveRenderer
                SequentialAnimation on opacity {
                    running: reactor.alert && !power.lowPower; loops: Animation.Infinite
                    NumberAnimation { from: 0.2; to: 1; duration: 450; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1; to: 0.2; duration: 450; easing.type: Easing.InOutSine }
                }
                ShapePath {
                        fillColor: Qt.rgba(1, 0.165, 0.31, 0.07); strokeColor: root.red; strokeWidth: 2; joinStyle: ShapePath.MiterJoin
                    startX: 12; startY: 1
                    PathLine { x: hud.width + 7; y: 1 } PathLine { x: hud.width + 7; y: hud.height - 7 }
                    PathLine { x: hud.width - 5; y: hud.height + 5 } PathLine { x: 1; y: hud.height + 5 }
                    PathLine { x: 1; y: 12 } PathLine { x: 12; y: 1 }
                }
            }

            // operator line + link status
            Text {
                x: 58; y: 0
                text: "OPERATOR // " + root.label
                color: root.cy
                font.family: "Rajdhani"; font.bold: true; font.pixelSize: 14; font.letterSpacing: 3
            }
            Text {
                anchors.right: parent.right; y: 1
                text: root.statusText
                color: reactor.alert || power.lowPower ? root.red : Qt.rgba(0.36, 0.93, 0.86, 0.55)
                font.family: "Rajdhani"; font.bold: true; font.pixelSize: 11; font.letterSpacing: 2
                SequentialAnimation on opacity { loops: Animation.Infinite; running: !power.lowPower
                    PauseAnimation { duration: 3000 } NumberAnimation { to: 0.2; duration: 60 } NumberAnimation { to: 1; duration: 60 }
                    NumberAnimation { to: 0.4; duration: 50 } NumberAnimation { to: 1; duration: 80 } }
            }

            // level badge = uptime hours
            Item {
                x: 0; y: 2; width: 48; height: 48
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: Qt.rgba(1, 0.165, 0.31, 0.12); strokeColor: root.red; strokeWidth: 2; joinStyle: ShapePath.MiterJoin
                        startX: 10; startY: 1
                        PathLine { x: 47; y: 1 } PathLine { x: 47; y: 38 } PathLine { x: 38; y: 47 }
                        PathLine { x: 1; y: 47 } PathLine { x: 1; y: 10 } PathLine { x: 10; y: 1 }
                    }
                }
                Text {
                    anchors.centerIn: parent; anchors.verticalCenterOffset: -4
                    text: Math.floor((Number(uptime.value) || 0) / 3600)
                    color: root.red
                    font.family: "Orbitron"; font.bold: true; font.pixelSize: 20
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                    text: "UP·H"; color: root.red
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 9; font.letterSpacing: 1
                }
            }

            // integrity bar (free memory), segmented
            Row {
                x: 58; y: 20; spacing: 2
                Repeater {
                    model: 34
                    Rectangle {
                        required property int index
                        readonly property bool lit: index < Math.round(root.integrity * 34)
                        width: 10; height: 13
                        color: lit ? (root.integrity < 0.15 ? root.red : root.cy) : Qt.rgba(0.36, 0.93, 0.86, 0.12)
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
            }
            Text {
                x: 58; y: 36
                text: root.grouped(root.freeMB) + " / " + root.grouped(root.totalMB)
                color: root.cy
                font.family: "Orbitron"; font.pixelSize: 13
            }
            Text {
                x: 58 + 180; y: 38
                text: "MEM FREE"; color: Qt.rgba(0.36, 0.93, 0.86, 0.65)
                font.family: "Rajdhani"; font.bold: true; font.pixelSize: 11; font.letterSpacing: 3
            }
            Text {
                x: 58 + 34 * 12 - width - 2; y: 38
                text: "STORAGE " + (Number(disk.value) || 0).toFixed(0) + "%"
                color: Qt.rgba(1, 0.165, 0.31, 0.95)
                font.family: "Rajdhani"; font.bold: true; font.pixelSize: 11; font.letterSpacing: 2
            }
            Rectangle {   // storage: thin line under the numbers
                x: 58; y: 54; width: 34 * 12 - 2; height: 2; color: Qt.rgba(0.36, 0.93, 0.86, 0.15)
                Rectangle { width: parent.width * Math.max(0, Math.min(100, Number(disk.value) || 0)) / 100; height: 2; color: root.red }
            }

            // CELL CHARGE: only on machines with a battery
            Column {
                x: 476; y: 18; width: 72; spacing: 2
                visible: power.hasBattery
                Text {
                    text: "CELL CHARGE"
                    color: power.lowPower ? root.red : Qt.rgba(0.36, 0.93, 0.86, 0.65)
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 10; font.letterSpacing: 1
                }
                Row {
                    spacing: 2
                    Repeater {
                        model: 10
                        Rectangle {
                            required property int index
                            width: 5.4; height: 9
                            color: index < Math.ceil(power.percent / 10)
                                   ? (power.percent < Cfg.LOW_POWER ? root.red : root.cy) : Qt.rgba(0.36, 0.93, 0.86, 0.12)
                        }
                    }
                }
                Text {
                    text: power.percent + "%" + (power.charging ? " +" : "")
                    color: power.percent < Cfg.LOW_POWER ? root.red : root.cy
                    font.family: "Orbitron"; font.pixelSize: 11
                }
            }

            // CPU units (free capacity), like memory slots of a deck
            Text {
                x: 0; y: 66
                text: "CPU"; color: root.cy
                font.family: "Rajdhani"; font.bold: true; font.pixelSize: 14; font.letterSpacing: 3
            }
            Row {
                x: 40; y: 68; spacing: 4
                Repeater {
                    model: 12
                    Shape {
                        id: unit
                        required property int index
                        readonly property bool lit: index < Math.round(root.cpuFree * 12)
                        width: 15; height: 13
                        ShapePath {
                            fillColor: unit.lit ? root.cy : "transparent"
                            strokeColor: Qt.rgba(0.36, 0.93, 0.86, unit.lit ? 1 : 0.4); strokeWidth: 1
                            startX: 0.5; startY: 0.5
                            PathLine { x: 14.5; y: 0.5 } PathLine { x: 14.5; y: 8.5 } PathLine { x: 10; y: 12.5 }
                            PathLine { x: 0.5; y: 12.5 } PathLine { x: 0.5; y: 0.5 }
                        }
                    }
                }
            }
            Text {
                x: 40 + 12 * 19 + 6; y: 67
                text: (Number(cpu.value) || 0).toFixed(0) + "% LOAD"
                color: root.cy
                font.family: "Orbitron"; font.pixelSize: 12
            }

            // network chips
            Row {
                anchors.right: parent.right; y: 64; spacing: 8
                Repeater {
                    model: [["▼", down], ["▲", up]]
                    Rectangle {
                        required property var modelData
                        width: 80; height: 20; color: Qt.rgba(0.36, 0.93, 0.86, 0.1)
                        border.color: Qt.rgba(0.36, 0.93, 0.86, 0.5); border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: modelData[0] + " " + root.rate(modelData[1].value) + "/s"
                            color: root.cy
                            font.family: "Rajdhani"; font.bold: true; font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}
