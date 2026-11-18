// CyberNeon v3 splash - "jack-in" boot sequence for Plasma 6 (KSplashQML). Original artwork.
// The animated CyberNeon wallpaper (same as the desktop) starts behind a dimmed jack-in terminal with GPU glow;
// at the last stage the terminal fades and the desktop appears over the same moving background.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Rectangle {
    id: root
    color: "#070d1a"

    property int stage: 0                       // set by ksplash (1..6)
    readonly property real progress: Math.min(1, stage / 6)
    readonly property color cy: "#5beedc"
    readonly property color red: "#ff2a4f"
    readonly property var lines: [
        "NEURAL LINK ............ OK",
        "ICE HANDSHAKE .......... OK",
        "PROXY CHAIN ............ 7 HOPS",
        "DAEMON LOADER .......... ARMED",
        "SESSION KEY ............ CRACKED",
        "USER SPACE ............. ONLINE"
    ]

    CyberNeonLive {
        id: bg
        anchors.fill: parent
        source: "@WALLPAPER@"                    // filled in by install.sh
    }
    // dim layer with a spotlight on the wallpaper's sigil (the logo "powers on"); it lifts as the session loads
    readonly property real sx: bg.mx(1920)
    readonly property real sy: bg.my(1010)
    readonly property real ring: 650 * bg.sc
    Shape {
        anchors.fill: parent
        opacity: 1.0 - 0.45 * root.progress
        Behavior on opacity { NumberAnimation { duration: 500 } }
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.sx; centerY: root.sy; centerRadius: root.ring * 1.25
                focalX: root.sx; focalY: root.sy
                GradientStop { position: 0.0; color: Qt.rgba(0.027, 0.051, 0.102, 0.05) }
                GradientStop { position: 0.55; color: Qt.rgba(0.027, 0.051, 0.102, 0.35) }
                GradientStop { position: 1.0; color: Qt.rgba(0.027, 0.051, 0.102, 0.9) }
            }
            startX: 0; startY: 0
            PathLine { x: root.width; y: 0 } PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: root.height } PathLine { x: 0; y: 0 }
        }
        SequentialAnimation on opacity {   // power-on flicker of the whole scene
            running: true
            NumberAnimation { from: 1; to: 0.6; duration: 80 }
            NumberAnimation { to: 1; duration: 60 }
            PauseAnimation { duration: 140 }
            NumberAnimation { to: 0.75; duration: 50 }
            NumberAnimation { to: 1; duration: 90 }
        }
    }

    Item {
        id: terminal
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: root.cy; shadowBlur: 0.7; blurMax: 20
                                    shadowOpacity: 0.7; shadowHorizontalOffset: 0; shadowVerticalOffset: 0; autoPaddingEnabled: true }

        // corner brackets
        Repeater {
            model: 4
            Item {
                required property int index
                readonly property bool r: index % 2 === 1
                readonly property bool b: index > 1
                x: r ? root.width - 120 : 40; y: b ? root.height - 120 : 40
                width: 80; height: 80
                Rectangle { width: 80; height: 4; color: root.red; y: parent.b ? 76 : 0 }
                Rectangle { width: 4; height: 80; color: root.red; x: parent.r ? 76 : 0 }
            }
        }

        Column {   // above the sigil ring
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(40, root.sy - root.ring - height - 24)
            spacing: 14
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Text {
                    id: jack
                    property int shown: 0
                    readonly property string full: "// JACKING IN"
                    text: full.substring(0, shown)
                    color: root.cy
                    font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 30; font.letterSpacing: 4
                    NumberAnimation on shown { from: 0; to: 13; duration: 650 }   // typed in
                }
                Rectangle {   // blinking cursor
                    width: 14; height: 30; color: root.red; anchors.verticalCenter: parent.verticalCenter
                    SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0; duration: 1 } PauseAnimation { duration: 420 } NumberAnimation { to: 1; duration: 1 } PauseAnimation { duration: 420 } }
                }
            }
            Item {   // hatched progress bar
                anchors.horizontalCenter: parent.horizontalCenter
                width: 560; height: 18
                Rectangle { anchors.fill: parent; color: Qt.rgba(0.027, 0.051, 0.102, 0.6); border.color: Qt.rgba(0.36, 0.93, 0.86, 0.6); border.width: 1 }
                Item {
                    x: 3; y: 3; height: parent.height - 6
                    width: (parent.width - 6) * root.progress
                    clip: true
                    Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    Repeater {
                        model: 80
                        Rectangle {
                            required property int index
                            x: index * 10 - 12; y: -4; width: 5; height: 22
                            rotation: 35; color: root.cy
                        }
                    }
                }
            }
        }

        Column {   // status lines, below the sigil ring
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.min(root.height - height - 100, root.sy + root.ring + 18)
            spacing: 3
            Repeater {
                model: root.lines.length
                Text {
                    required property int index
                    text: root.lines[index]
                    visible: root.stage > index
                    color: index === root.stage - 1 ? root.cy : Qt.rgba(0.49, 0.87, 0.84, 0.6)
                    font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 15
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 66
            text: "FAN MADE // INSPIRED BY CYBERPUNK 2077 BY CD PROJEKT RED"
            color: Qt.rgba(0.36, 0.93, 0.86, 0.4)
            font.family: "Chakra Petch"; font.pixelSize: 12; font.letterSpacing: 2
        }

        OpacityAnimator { id: outro; target: terminal; from: 1; to: 0; duration: 600 }
    }
    onStageChanged: if (stage >= 6) outro.start()
}
