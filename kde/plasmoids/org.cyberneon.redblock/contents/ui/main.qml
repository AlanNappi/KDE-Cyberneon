// CyberNeon Red Block - the neon red block at 76-110 px of the top bar, above the bar's neon line,
// where the dock's red bar meets it (same as the Budgie version). It places itself in screen
// coordinates, so it does not depend on the panel's inner margins.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    fullRepresentation: Item {
        id: cell
        readonly property int blockLeft: 76
        readonly property int blockRight: 110
        property real gx: 0
        property real gy: 0
        function sync() { var p = cell.mapToItem(null, 0, 0); gx = p.x; gy = p.y }

        Layout.minimumWidth: blockRight
        Layout.preferredWidth: blockRight
        Layout.maximumWidth: blockRight
        Layout.fillHeight: true
        clip: false
        onXChanged: sync()
        onYChanged: sync()
        Component.onCompleted: sync()
        Timer { interval: 1000; running: true; repeat: true; onTriggered: cell.sync() }   // panel layout settles late

        Rectangle {
            x: cell.blockLeft - cell.gx
            y: -cell.gy
            width: cell.blockRight - cell.blockLeft
            height: (cell.Window.height > 0 ? cell.Window.height : 34) - 2   // leave the 2 px hot core of the line
            color: "#ff2a4f"
        }
    }
}
