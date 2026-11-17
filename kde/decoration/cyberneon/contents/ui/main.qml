// CyberNeon - KWin window decoration in QML (Plasma 6, X11 and Wayland). Original artwork.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
//
// One neon-red frame polygon with a big 45deg cut (top-left) and a small cut (bottom-right), hollow centre
// (translucent apps never show red behind them), a light "neon core" line along the inner edge,
// HUD ticks + uppercase title, cut-corner buttons, a cyan status segment on the bottom border.
import QtQuick
import QtQuick.Shapes
import org.kde.kwin.decoration

Decoration {
    id: root
    alpha: true

    readonly property color red: "#ff2a4f"
    readonly property color redDim: "#8c1a33"
    readonly property color hot: "#ff8fa3"
    readonly property color navy: "#111e29"
    readonly property color cyan: "#5beedc"

    readonly property bool active: decoration.client.active
    readonly property bool maxed: decoration.client.maximized
    readonly property color frameColor: active ? red : redDim

    readonly property int titleH: 24
    readonly property int side: maxed ? 0 : 4
    readonly property int bottomB: maxed ? 0 : 7
    readonly property int cut: maxed ? 0 : 22        // big 45deg cut, top-left
    readonly property int brCut: maxed ? 0 : 12      // small cut, bottom-right
    property int buttonSize: 18

    DecorationOptions { id: options; deco: decoration }

    // ------------------------------------------------------------ frame (outer polygon minus client hole)
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.frameColor
            strokeWidth: -1
            fillRule: ShapePath.OddEvenFill
            // outer outline
            startX: root.cut; startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height - root.brCut }
            PathLine { x: root.width - root.brCut; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: 0; y: root.cut }
            PathLine { x: root.cut; y: 0 }
            // client hole
            PathMove { x: root.side; y: root.titleH }
            PathLine { x: root.width - root.side; y: root.titleH }
            PathLine { x: root.width - root.side; y: root.height - root.bottomB }
            PathLine { x: root.side; y: root.height - root.bottomB }
            PathLine { x: root.side; y: root.titleH }
        }
        // neon core: thin light line along the inner edge of the frame (active windows only)
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.active && !root.maxed ? Qt.rgba(1, 0.56, 0.64, 0.9) : "transparent"
            strokeWidth: 1
            startX: root.side - 0.5; startY: root.titleH - 0.5
            PathLine { x: root.width - root.side + 0.5; y: root.titleH - 0.5 }
            PathLine { x: root.width - root.side + 0.5; y: root.height - root.bottomB + 0.5 }
            PathLine { x: root.side - 0.5; y: root.height - root.bottomB + 0.5 }
            PathLine { x: root.side - 0.5; y: root.titleH - 0.5 }
        }
    }

    // cyan status segment on the bottom border (bottom-left)
    Rectangle {
        visible: !root.maxed
        x: 18; y: root.height - root.bottomB + 2
        width: 34; height: 3
        color: root.active ? root.cyan : Qt.rgba(0.36, 0.93, 0.86, 0.35)
    }

    // ------------------------------------------------------------ title row
    Item {
        id: titleRow
        x: root.maxed ? 6 : root.cut + 4
        y: 0
        width: root.width - x - (root.maxed ? 4 : root.side + 2)
        height: root.titleH

        Row {   // HUD ticks
            id: ticks
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Repeater {
                model: 3
                Rectangle { width: 4; height: 4; color: root.navy; opacity: root.active ? 1 : 0.6 }
            }
        }

        Text {
            id: caption
            anchors.left: ticks.right
            anchors.leftMargin: 9
            anchors.right: rightButtons.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: decoration.client.caption
            textFormat: Text.PlainText
            color: root.navy
            opacity: root.active ? 1 : 0.8
            font.family: "Chakra Petch"
            font.bold: true
            font.pixelSize: 13
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            renderType: Text.NativeRendering
        }

        ButtonGroup {
            id: leftButtons
            visible: false
            spacing: 4
            explicitSpacer: root.buttonSize
            menuButton: menuButtonComponent
            appMenuButton: appMenuButtonComponent
            minimizeButton: minimizeButtonComponent
            maximizeButton: maximizeButtonComponent
            keepBelowButton: keepBelowButtonComponent
            keepAboveButton: keepAboveButtonComponent
            helpButton: helpButtonComponent
            shadeButton: shadeButtonComponent
            allDesktopsButton: stickyButtonComponent
            closeButton: closeButtonComponent
            buttons: options.titleButtonsLeft
        }

        ButtonGroup {
            id: rightButtons
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: (root.titleH - root.buttonSize) / 2   // ButtonGroup has no height of its own
            spacing: 4
            explicitSpacer: root.buttonSize
            menuButton: menuButtonComponent
            appMenuButton: appMenuButtonComponent
            minimizeButton: minimizeButtonComponent
            maximizeButton: maximizeButtonComponent
            keepBelowButton: keepBelowButtonComponent
            keepAboveButton: keepAboveButtonComponent
            helpButton: helpButtonComponent
            shadeButton: shadeButtonComponent
            allDesktopsButton: stickyButtonComponent
            closeButton: closeButtonComponent
            buttons: options.titleButtonsRight
        }

        Component.onCompleted: decoration.installTitleItem(titleRow)
    }

    // ------------------------------------------------------------ buttons
    Component { id: minimizeButtonComponent;   CyberNeonButton { buttonType: DecorationOptions.DecorationButtonMinimize;        size: root.buttonSize } }
    Component { id: maximizeButtonComponent;   CyberNeonButton { buttonType: DecorationOptions.DecorationButtonMaximizeRestore; size: root.buttonSize } }
    Component { id: closeButtonComponent;      CyberNeonButton { buttonType: DecorationOptions.DecorationButtonClose;           size: root.buttonSize } }
    Component { id: keepBelowButtonComponent;  CyberNeonButton { buttonType: DecorationOptions.DecorationButtonKeepBelow;       size: root.buttonSize } }
    Component { id: keepAboveButtonComponent;  CyberNeonButton { buttonType: DecorationOptions.DecorationButtonKeepAbove;       size: root.buttonSize } }
    Component { id: helpButtonComponent;       CyberNeonButton { buttonType: DecorationOptions.DecorationButtonQuickHelp;       size: root.buttonSize } }
    Component { id: shadeButtonComponent;      CyberNeonButton { buttonType: DecorationOptions.DecorationButtonShade;           size: root.buttonSize } }
    Component { id: stickyButtonComponent;     CyberNeonButton { buttonType: DecorationOptions.DecorationButtonOnAllDesktops;   size: root.buttonSize } }
    Component { id: appMenuButtonComponent;    CyberNeonButton { buttonType: DecorationOptions.DecorationButtonApplicationMenu; size: root.buttonSize } }
    Component { id: menuButtonComponent;       MenuButton { width: root.buttonSize; height: root.buttonSize } }

    function applyBorders() {
        borders.setBorders(4)
        borders.setTitle(titleH)
        borders.bottom = 7
        maximizedBorders.setBorders(0)
        maximizedBorders.setTitle(titleH)
        extendedBorders.setAllBorders(4)       // easier resizing
    }
    Component.onCompleted: applyBorders()
}
