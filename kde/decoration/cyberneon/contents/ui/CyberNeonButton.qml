// CyberNeon v3 titlebar button: cut-corner plate outlined in cyan with a cyan glyph; hover = lit plate (cyan,
// close: red) with a navy glyph and a soft glow. Original artwork. FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED.
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import org.kde.kwin.decoration

DecorationButton {
    id: button
    property real size: 20
    width: size
    height: size

    readonly property color navy: "#0d1822"
    readonly property color cyan: "#5beedc"
    readonly property color red: "#ff2a4f"
    readonly property bool isClose: buttonType == DecorationOptions.DecorationButtonClose
    readonly property bool lit: hovered || pressed
    readonly property bool winActive: decoration.client.active
    readonly property color accent: isClose ? red : cyan
    readonly property real s: size / 18

    readonly property string glyph: {
        switch (buttonType) {
        case DecorationOptions.DecorationButtonMinimize:
            return "M 5 12 L 13 12";
        case DecorationOptions.DecorationButtonMaximizeRestore:
            return decoration.client.maximized
                ? "M 5 7 L 11 7 L 11 13 L 5 13 Z M 7.5 4.5 L 13.5 4.5 L 13.5 10.5"
                : "M 5 5 L 13 5 L 13 13 L 5 13 Z";
        case DecorationOptions.DecorationButtonClose:
            return "M 5.5 5.5 L 12.5 12.5 M 12.5 5.5 L 5.5 12.5";
        case DecorationOptions.DecorationButtonKeepAbove:
            return "M 5 11.5 L 9 6.5 L 13 11.5";
        case DecorationOptions.DecorationButtonKeepBelow:
            return "M 5 6.5 L 9 11.5 L 13 6.5";
        case DecorationOptions.DecorationButtonShade:
            return "M 5 7 L 13 7";
        case DecorationOptions.DecorationButtonOnAllDesktops:
            return "M 7.5 7.5 L 10.5 7.5 L 10.5 10.5 L 7.5 10.5 Z";
        case DecorationOptions.DecorationButtonQuickHelp:
            return "M 7 7 L 9 5 L 11 7 L 9 9 L 9 10.5 M 9 12.5 L 9 13.5";
        default:
            return "M 6 9 L 12 9";
        }
    }

    Item {
        id: plate
        anchors.fill: parent
        visible: false
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {   // plate with the bottom-right corner cut
                fillColor: button.lit ? button.accent : "transparent"
                strokeColor: button.lit ? button.accent : Qt.rgba(0.36, 0.93, 0.86, button.winActive ? 0.55 : 0.25)
                strokeWidth: 1.2
                joinStyle: ShapePath.MiterJoin
                startX: 1 * button.s; startY: 1 * button.s
                PathLine { x: 17 * button.s; y: 1 * button.s }
                PathLine { x: 17 * button.s; y: 13 * button.s }
                PathLine { x: 13 * button.s; y: 17 * button.s }
                PathLine { x: 1 * button.s; y: 17 * button.s }
                PathLine { x: 1 * button.s; y: 1 * button.s }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: button.lit ? button.navy
                                        : (button.isClose ? Qt.rgba(1, 0.165, 0.31, button.winActive ? 1 : 0.4)
                                                          : Qt.rgba(0.36, 0.93, 0.86, button.winActive ? 1 : 0.4))
                strokeWidth: 1.7
                capStyle: ShapePath.SquareCap
                joinStyle: ShapePath.MiterJoin
                scale: Qt.size(button.s, button.s)
                PathSvg { path: button.glyph }
            }
        }
    }
    MultiEffect {
        source: plate
        anchors.fill: plate
        shadowEnabled: button.lit
        shadowColor: button.accent
        shadowBlur: 0.8
        blurMax: 12
        shadowOpacity: 0.9
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        autoPaddingEnabled: true
    }
}
