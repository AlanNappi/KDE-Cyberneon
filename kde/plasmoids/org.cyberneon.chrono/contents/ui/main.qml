// CyberNeon Chrono - bottom-right HUD counter for Plasma 6 (X11 and Wayland). Original artwork.
// The time is shown like a magazine counter: HH:MM as the count, the seconds left in the minute as the reserve,
// and 60 ticks that deplete every minute (last ten in red). Short RGB-split glitch every ~12 s.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root
    readonly property color cy: "#5beedc"
    readonly property color red: "#ff2a4f"
    property date now: new Date()
    property bool glitching: false
    readonly property int remaining: 60 - now.getSeconds()

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }
    Timer { interval: 12000; running: true; repeat: true; onTriggered: { root.glitching = true; glitchOff.restart() } }
    Timer { id: glitchOff; interval: 140; onTriggered: root.glitching = false }

    fullRepresentation: Item {
        implicitWidth: 420
        implicitHeight: 160

        Item {
            id: face
            anchors.fill: parent
            anchors.margins: 12
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: root.cy; shadowBlur: 0.8; blurMax: 22
                                        shadowOpacity: 0.75; shadowHorizontalOffset: 0; shadowVerticalOffset: 0; autoPaddingEnabled: true }

            Row {
                id: count
                anchors.right: parent.right
                spacing: 10
                Text {
                    id: hm
                    text: Qt.formatTime(root.now, "HH:mm")
                    color: root.cy
                    font.family: "Orbitron"; font.weight: Font.Medium; font.pixelSize: 72
                }
                Column {
                    anchors.bottom: hm.baseline
                    spacing: -2
                    Text { text: "/"; color: Qt.rgba(0.36, 0.93, 0.86, 0.6); font.family: "Orbitron"; font.pixelSize: 22 }
                    Text {
                        text: root.remaining.toString().padStart(2, "0")
                        color: root.remaining <= 10 ? root.red : root.cy
                        font.family: "Orbitron"; font.pixelSize: 26
                    }
                }
            }
            // depleting ticks
            Row {
                anchors.right: parent.right
                anchors.top: count.bottom; anchors.topMargin: 2
                spacing: 2
                Repeater {
                    model: 60
                    Rectangle {
                        required property int index
                        readonly property bool lit: index < root.remaining
                        width: 4; height: index % 10 === 0 ? 14 : 10
                        anchors.bottom: parent.bottom
                        color: lit ? (index < 10 ? root.red : root.cy) : Qt.rgba(0.36, 0.93, 0.86, 0.12)
                    }
                }
            }
            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 10
                Shape {   // small chamfered tag
                    width: 70; height: 18; anchors.verticalCenter: parent.verticalCenter
                    ShapePath { fillColor: root.red; strokeWidth: -1
                        startX: 0; startY: 0; PathLine { x: 70; y: 0 } PathLine { x: 70; y: 12 } PathLine { x: 64; y: 18 }
                        PathLine { x: 0; y: 18 } PathLine { x: 0; y: 0 } }
                    Text { anchors.centerIn: parent; text: "CHRONO"; color: "#0b1620"
                           font.family: "Rajdhani"; font.bold: true; font.pixelSize: 12; font.letterSpacing: 2 }
                }
                Text {
                    text: Qt.formatDate(root.now, "dddd").toUpperCase() + "  //  " + Qt.formatDate(root.now, "dd.MM.yyyy")
                    color: root.red
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 18; font.letterSpacing: 2
                }
            }
        }

        // RGB split glitch
        ShaderEffectSource {
            visible: root.glitching
            sourceItem: face; x: face.x - 5; y: face.y; width: face.width; height: face.height
            opacity: 0.7
            layer.enabled: true
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: root.red }
        }
        ShaderEffectSource {
            visible: root.glitching
            sourceItem: face; x: face.x + 5; y: face.y; width: face.width; height: face.height
            opacity: 0.7
            layer.enabled: true
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: root.cy }
        }
    }
}
