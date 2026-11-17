// CyberNeon - SDDM login theme (Qt 6 / SDDM >= 0.21, Plasma 6).
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
// Preview before enabling:  sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/cyberneon
import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#070d1a"

    readonly property color cy: "#5beedc"
    readonly property color cyText: "#7eddd5"
    readonly property color red: "#ff2a4f"
    readonly property color navy: "#111e29"
    readonly property color view: "#0b1620"
    property date now: new Date()

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // ------------------------------------------------------------ clock (top right)
    Column {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 60
        anchors.topMargin: 50
        spacing: -8
        Text {
            anchors.right: parent.right
            text: Qt.formatTime(root.now, "HH:mm")
            color: root.cy
            font.family: "Orbitron"; font.weight: Font.Medium; font.pixelSize: 96
        }
        Text {
            anchors.right: parent.right
            text: Qt.formatDate(root.now, "dddd") + "  //  " + Qt.formatDate(root.now, "dd.MM.yyyy")
            color: root.red
            font.family: "Chakra Petch"; font.weight: Font.DemiBold; font.pixelSize: 26
        }
    }

    // ------------------------------------------------------------ login box
    Rectangle {
        id: box
        x: parent.width * 0.11
        anchors.verticalCenter: parent.verticalCenter
        width: 500
        height: 300
        color: Qt.rgba(0.067, 0.118, 0.161, 0.92)
        border.color: root.red
        border.width: 2

        Rectangle {   // red header strip with the 45deg cut look
            x: 0; y: 0; width: parent.width; height: 34
            color: root.red
            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: 24
                text: "// ACCESS POINT  " + sddm.hostName
                color: root.navy
                font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 16
            }
        }

        Column {
            x: 30; y: 60
            width: parent.width - 60
            spacing: 14

            TextField {
                id: user
                width: parent.width
                text: userModel.lastUser
                placeholderText: "user"
                color: root.cy
                font.family: "Chakra Petch"; font.pixelSize: 20; font.bold: true
                background: Rectangle { color: root.view; border.color: Qt.rgba(0.36, 0.93, 0.86, 0.6); border.width: 1 }
                KeyNavigation.tab: pass
            }

            TextField {
                id: pass
                width: parent.width
                echoMode: TextInput.Password
                placeholderText: "password"
                color: root.cy
                font.family: "Chakra Petch"; font.pixelSize: 20
                background: Rectangle { color: root.view; border.color: pass.activeFocus ? root.cy : Qt.rgba(0.36, 0.93, 0.86, 0.6); border.width: 1 }
                onAccepted: sddm.login(user.text, pass.text, session.currentIndex)
                KeyNavigation.tab: session
            }

            Row {
                width: parent.width
                spacing: 10
                ComboBox {
                    id: session
                    width: parent.width - loginBtn.width - 10
                    model: sessionModel
                    textRole: "name"
                    currentIndex: sessionModel.lastIndex
                    font.family: "Chakra Petch"; font.pixelSize: 15
                }
                Button {
                    id: loginBtn
                    width: 140
                    text: "JACK IN"
                    font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 16
                    onClicked: sddm.login(user.text, pass.text, session.currentIndex)
                    contentItem: Text { text: loginBtn.text; font: loginBtn.font; color: root.navy
                                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: loginBtn.down ? "#9ff0e8" : root.cy }
                }
            }

            Text {
                id: message
                text: ""
                color: root.red
                font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 15
            }
        }
    }

    // ------------------------------------------------------------ power buttons (bottom right)
    Row {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 40
        spacing: 12
        Button { text: "REBOOT";   visible: sddm.canReboot;   onClicked: sddm.reboot()
                 font.family: "Chakra Petch"; font.bold: true }
        Button { text: "SHUTDOWN"; visible: sddm.canPowerOff; onClicked: sddm.powerOff()
                 font.family: "Chakra Petch"; font.bold: true }
    }

    Connections {
        target: sddm
        function onLoginFailed() { message.text = "ACCESS DENIED"; pass.text = ""; pass.forceActiveFocus() }
        function onLoginSucceeded() { message.text = "" }
    }

    Component.onCompleted: {
        if (user.text.length > 0) pass.forceActiveFocus(); else user.forceActiveFocus()
    }
}
