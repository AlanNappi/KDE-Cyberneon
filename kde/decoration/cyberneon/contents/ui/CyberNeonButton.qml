// CyberNeon titlebar button: cut-corner square (navy outline), glyph; hover = filled navy plate with a cyan
// glyph (close: red). Original artwork. FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED.
import QtQuick
import QtQuick.Shapes
import org.kde.kwin.decoration

DecorationButton {
    id: button
    property real size: 18
    width: size
    height: size

    readonly property color navy: "#111e29"
    readonly property bool isClose: buttonType == DecorationOptions.DecorationButtonClose
    readonly property bool lit: hovered || pressed
    readonly property color glyphColor: lit ? (isClose ? "#ff2a4f" : "#5beedc") : navy
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
            return "M 5 5 L 13 13 M 13 5 L 5 13";
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

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        // plate with the bottom-right corner cut
        ShapePath {
            fillColor: button.lit ? button.navy : "transparent"
            strokeColor: button.navy
            strokeWidth: 1.5
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
            strokeColor: button.glyphColor
            strokeWidth: 1.8
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.MiterJoin
            scale: Qt.size(button.s, button.s)
            PathSvg { path: button.glyph }
        }
    }
}
