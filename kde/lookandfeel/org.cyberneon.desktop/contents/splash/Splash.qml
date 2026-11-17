// CyberNeon splash - "jack-in" boot sequence for Plasma 6 (KSplashQML). Original artwork.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import org.kde.kirigami as Kirigami

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

    Column {
        anchors.centerIn: parent
        spacing: 28

        Kirigami.Icon {
            id: logo
            anchors.horizontalCenter: parent.horizontalCenter
            width: 180; height: 180
            source: "cyberneon-launcher"
            fallback: "cyberneon-logo"
            opacity: 0
            SequentialAnimation on opacity {   // power-on flicker
                running: true
                NumberAnimation { to: 1; duration: 90 }
                NumberAnimation { to: 0.2; duration: 70 }
                NumberAnimation { to: 1; duration: 60 }
                PauseAnimation { duration: 120 }
                NumberAnimation { to: 0.5; duration: 50 }
                NumberAnimation { to: 1; duration: 80 }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            Text {
                text: "// JACKING IN"
                color: root.cy
                font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 30; font.letterSpacing: 4
            }
            Rectangle {   // blinking cursor
                width: 14; height: 30; color: root.red; anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity { loops: Animation.Infinite; NumberAnimation { to: 0; duration: 1 } PauseAnimation { duration: 420 } NumberAnimation { to: 1; duration: 1 } PauseAnimation { duration: 420 } }
            }
        }

        Item {   // hatched progress bar
            anchors.horizontalCenter: parent.horizontalCenter
            width: 560; height: 18
            Rectangle { anchors.fill: parent; color: "transparent"; border.color: Qt.rgba(0.36, 0.93, 0.86, 0.5); border.width: 1 }
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

        Column {   // status lines, one per stage
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            Repeater {
                model: root.lines.length
                Text {
                    required property int index
                    text: root.lines[index]
                    visible: root.stage > index
                    color: index === root.stage - 1 ? root.cy : Qt.rgba(0.49, 0.87, 0.84, 0.55)
                    font.family: "JetBrainsMono Nerd Font Mono"; font.pixelSize: 15
                }
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 66
        text: "FAN MADE // INSPIRED BY CYBERPUNK 2077 BY CD PROJEKT RED"
        color: Qt.rgba(0.36, 0.93, 0.86, 0.35)
        font.family: "Chakra Petch"; font.pixelSize: 12; font.letterSpacing: 2
    }

    OpacityAnimator {
        id: outro; target: root; from: 1; to: 0; duration: 600
    }
    onStageChanged: if (stage >= 6) outro.start()
}
