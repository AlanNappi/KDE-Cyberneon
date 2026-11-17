// CyberNeon Clock - Plasma 6 desktop widget (works on X11 and Wayland).
// Same look as the ShowTime clock of the Budgie version: cyan Orbitron time, red date.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root
    property date now: new Date()

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: root.now = new Date()
    }

    fullRepresentation: Item {
        implicitWidth: 330
        implicitHeight: 140

        Column {
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: -8

            Text {
                anchors.right: parent.right
                text: Qt.formatTime(root.now, "HH:mm")
                color: "#5beedc"
                font.family: "Orbitron"
                font.weight: Font.Medium
                font.pixelSize: 80
            }
            Text {
                anchors.right: parent.right
                text: Qt.formatDate(root.now, "dddd") + "  //  " + Qt.formatDate(root.now, "dd.MM.yyyy")
                color: "#fb3048"
                font.family: "Chakra Petch"
                font.weight: Font.DemiBold
                font.pixelSize: 23
            }
        }
    }
}
