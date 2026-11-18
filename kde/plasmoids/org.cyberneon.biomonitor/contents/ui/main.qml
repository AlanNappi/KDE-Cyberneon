// CyberNeon Biomonitor - top-left HUD status block for Plasma 6 (X11 and Wayland). Original artwork.
// Real system data in a game-HUD layout: level badge = uptime hours, segmented "integrity" bar = free memory,
// unit blocks = free CPU, thin bar = storage, network rates, operator name.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    readonly property string label: "@HUD_LABEL@"          // replaced by install.sh (HUD_LABEL)
    readonly property color cy: "#5beedc"
    readonly property color red: "#ff2a4f"
    readonly property color navy: "#0b1620"

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Sensors.Sensor { id: cpu;    sensorId: "cpu/all/usage";               updateRateLimit: 1000 }
    Sensors.Sensor { id: memFree; sensorId: "memory/physical/free";       updateRateLimit: 2000 }
    Sensors.Sensor { id: memTot; sensorId: "memory/physical/total";       updateRateLimit: 60000 }
    Sensors.Sensor { id: disk;   sensorId: "disk/all/usedPercent";        updateRateLimit: 10000 }
    Sensors.Sensor { id: down;   sensorId: "network/all/download";        updateRateLimit: 1000 }
    Sensors.Sensor { id: up;     sensorId: "network/all/upload";          updateRateLimit: 1000 }
    Sensors.Sensor { id: uptime; sensorId: "os/system/uptime";            updateRateLimit: 60000 }

    readonly property real freeMB: (Number(memFree.value) || 0) / 1048576
    readonly property real totalMB: Math.max(1, (Number(memTot.value) || 0) / 1048576)
    readonly property real integrity: Math.max(0, Math.min(1, freeMB / totalMB))
    readonly property real cpuFree: 1 - Math.max(0, Math.min(100, Number(cpu.value) || 0)) / 100

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
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: root.cy; shadowBlur: 0.6; blurMax: 16
                                        shadowOpacity: 0.6; shadowHorizontalOffset: 0; shadowVerticalOffset: 0; autoPaddingEnabled: true }

            // operator line + link status
            Text {
                x: 58; y: 0
                text: "OPERATOR // " + root.label
                color: root.cy
                font.family: "Rajdhani"; font.bold: true; font.pixelSize: 14; font.letterSpacing: 3
            }
            Text {
                anchors.right: parent.right; y: 1
                text: "LINK STABLE  //  ID 0x" + (root.label.length * 4097 + 2077).toString(16).toUpperCase()
                color: Qt.rgba(0.36, 0.93, 0.86, 0.55)
                font.family: "Rajdhani"; font.bold: true; font.pixelSize: 11; font.letterSpacing: 2
                SequentialAnimation on opacity { loops: Animation.Infinite
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
                        required property int index
                        readonly property bool lit: index < Math.round(root.cpuFree * 12)
                        width: 15; height: 13
                        ShapePath {
                            fillColor: parent.lit ? root.cy : "transparent"
                            strokeColor: Qt.rgba(0.36, 0.93, 0.86, parent.lit ? 1 : 0.4); strokeWidth: 1
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
