// CyberNeon v3 - SDDM login theme (Qt 6 / SDDM >= 0.21, Plasma 6). Original artwork.
// The animated CyberNeon wallpaper (CyberNeonLive.qml, the same as the desktop) behind a glass "access terminal"
// with cut corners and a GPU neon glow.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
// Preview before enabling:  sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/cyberneon
import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#070d1a"

    readonly property color cy: "#5beedc"
    readonly property color cyText: "#7eddd5"
    readonly property color red: "#ff2a4f"
    readonly property color navy: "#0b1620"
    property date now: new Date()

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    CyberNeonLive {
        anchors.fill: parent
        source: config.background
    }
    Rectangle { anchors.fill: parent; color: "#070d1a"; opacity: 0.25 }

    // ------------------------------------------------------------ clock (top right)
    Item {
        anchors.right: parent.right; anchors.top: parent.top
        anchors.rightMargin: 60; anchors.topMargin: 44
        width: 520; height: 170
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: root.cy; shadowBlur: 0.8; blurMax: 24
                                    shadowOpacity: 0.8; shadowHorizontalOffset: 0; shadowVerticalOffset: 0; autoPaddingEnabled: true }
        Column {
            anchors.right: parent.right
            spacing: -8
            Text {
                anchors.right: parent.right
                text: Qt.formatTime(root.now, "HH:mm")
                color: root.cy
                font.family: "Orbitron"; font.weight: Font.Medium; font.pixelSize: 96
            }
            Text {
                anchors.right: parent.right
                text: Qt.formatDate(root.now, "dddd").toUpperCase() + "  //  " + Qt.formatDate(root.now, "dd.MM.yyyy")
                color: root.red
                font.family: "Chakra Petch"; font.weight: Font.DemiBold; font.pixelSize: 24; font.letterSpacing: 2
            }
        }
    }

    // ------------------------------------------------------------ access terminal
    Item {
        id: box
        x: parent.width * 0.06            // under the terminal drawn in the wallpaper, above its alarm strip
        y: parent.height * 0.4
        width: 520; height: 330

        Item {
            id: frame
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: root.red; shadowBlur: 1.0; blurMax: 30
                                        shadowOpacity: 0.85; shadowHorizontalOffset: 0; shadowVerticalOffset: 0; autoPaddingEnabled: true }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: Qt.rgba(0.043, 0.086, 0.125, 0.82)
                    strokeColor: root.red; strokeWidth: 2.5; joinStyle: ShapePath.MiterJoin
                    startX: 26; startY: 1.25
                    PathLine { x: box.width - 1.25; y: 1.25 }
                    PathLine { x: box.width - 1.25; y: box.height - 18 }
                    PathLine { x: box.width - 18; y: box.height - 1.25 }
                    PathLine { x: 1.25; y: box.height - 1.25 }
                    PathLine { x: 1.25; y: 26 }
                    PathLine { x: 26; y: 1.25 }
                }
                ShapePath {   // red header tab
                    fillColor: root.red; strokeWidth: -1
                    startX: 26; startY: 0
                    PathLine { x: 330; y: 0 }
                    PathLine { x: 306; y: 24 }
                    PathLine { x: 2; y: 24 }
                    PathLine { x: 26; y: 0 }
                }
            }
        }
        Text {
            x: 32; y: 0; height: 24; verticalAlignment: Text.AlignVCenter
            text: "// ACCESS POINT  " + sddm.hostName.toUpperCase()
            color: root.navy
            font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 14; font.letterSpacing: 2
        }

        Column {
            x: 34; y: 56
            width: parent.width - 68
            spacing: 14

            Text { text: "USER"; color: root.cyText; font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 12; font.letterSpacing: 3 }
            TextField {
                id: user
                width: parent.width; height: 42
                text: userModel.lastUser
                color: root.cy
                font.family: "Chakra Petch"; font.pixelSize: 20; font.bold: true
                leftPadding: 12
                background: CutField { focused: user.activeFocus }
                KeyNavigation.tab: pass
            }
            Text { text: "PASSPHRASE"; color: root.cyText; font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 12; font.letterSpacing: 3 }
            TextField {
                id: pass
                width: parent.width; height: 42
                echoMode: TextInput.Password
                passwordCharacter: "#"
                color: root.cy
                font.family: "Chakra Petch"; font.pixelSize: 20
                leftPadding: 12
                background: CutField { focused: pass.activeFocus }
                onAccepted: sddm.login(user.text, pass.text, session.currentIndex)
                KeyNavigation.tab: session
            }

            Row {
                width: parent.width
                spacing: 12
                ComboBox {
                    id: session
                    width: parent.width - loginBtn.width - 12; height: 40
                    model: sessionModel
                    textRole: "name"
                    currentIndex: sessionModel.lastIndex
                    font.family: "Chakra Petch"; font.pixelSize: 14
                    contentItem: Text { leftPadding: 12; text: session.displayText; font: session.font; color: root.cyText
                                        verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    background: CutField { focused: session.activeFocus }
                }
                Button {
                    id: loginBtn
                    width: 150; height: 40
                    text: "JACK IN"
                    font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 16; font.letterSpacing: 3
                    onClicked: sddm.login(user.text, pass.text, session.currentIndex)
                    contentItem: Text { text: loginBtn.text; font: loginBtn.font; color: root.navy
                                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Shape {
                        ShapePath {
                            fillColor: loginBtn.down ? "#9ff0e8" : (loginBtn.hovered ? "#8af7ea" : root.cy); strokeWidth: -1
                            startX: 0; startY: 0
                            PathLine { x: loginBtn.width; y: 0 }
                            PathLine { x: loginBtn.width; y: loginBtn.height - 10 }
                            PathLine { x: loginBtn.width - 10; y: loginBtn.height }
                            PathLine { x: 0; y: loginBtn.height }
                            PathLine { x: 0; y: 0 }
                        }
                    }
                }
            }

            Text {
                id: message
                text: ""
                color: root.red
                font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 15; font.letterSpacing: 2
            }
        }
    }

    component CutField: Shape {
        property bool focused: false
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: Qt.rgba(0.043, 0.086, 0.125, 0.9)
            strokeColor: parent.focused ? root.cy : Qt.rgba(0.36, 0.93, 0.86, 0.45)
            strokeWidth: parent.focused ? 2 : 1
            joinStyle: ShapePath.MiterJoin
            startX: 0.5; startY: 0.5
            PathLine { x: parent.width - 0.5; y: 0.5 }
            PathLine { x: parent.width - 0.5; y: parent.height - 10 }
            PathLine { x: parent.width - 10; y: parent.height - 0.5 }
            PathLine { x: 0.5; y: parent.height - 0.5 }
            PathLine { x: 0.5; y: 0.5 }
        }
    }

    // ------------------------------------------------------------ power buttons (bottom right)
    Row {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 40
        spacing: 14
        Repeater {
            model: [["REBOOT", sddm.canReboot, function () { sddm.reboot() }],
                    ["SHUTDOWN", sddm.canPowerOff, function () { sddm.powerOff() }]]
            Button {
                id: pb
                required property var modelData
                visible: modelData[1]
                width: 130; height: 34
                text: modelData[0]
                font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 13; font.letterSpacing: 2
                onClicked: modelData[2]()
                contentItem: Text { text: pb.text; font: pb.font; color: pb.hovered ? root.navy : root.cy
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: pb.hovered ? root.cy : Qt.rgba(0.043, 0.086, 0.125, 0.7)
                                        border.color: root.cy; border.width: 1 }
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 22
        text: "FAN MADE // INSPIRED BY CYBERPUNK 2077 BY CD PROJEKT RED"
        color: Qt.rgba(0.36, 0.93, 0.86, 0.35)
        font.family: "Chakra Petch"; font.pixelSize: 11; font.letterSpacing: 2
    }

    Connections {
        target: sddm
        function onLoginFailed() { message.text = "!! ACCESS DENIED"; pass.text = ""; pass.forceActiveFocus() }
        function onLoginSucceeded() { message.text = "" }
    }

    Component.onCompleted: {
        if (user.text.length > 0) pass.forceActiveFocus(); else user.forceActiveFocus()
    }
}
