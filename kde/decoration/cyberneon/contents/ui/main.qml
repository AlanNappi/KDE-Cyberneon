// CyberNeon v3 - KWin window decoration in QML (Plasma 6, X11 and Wayland). Original artwork.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
//
// Dark HUD titlebar inside a neon-red tube outline (big 45deg cut top-left, small cut bottom-right) with a real
// GPU-blurred neon glow: the glow is drawn in the decoration's `padding` area, which KWin turns into the window
// shadow. Red header tab with HUD ticks, cyan uppercase title, cut-corner buttons. Focus-in: the glow powers on
// with a flicker and a cyan sweep crosses the titlebar.
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import org.kde.kwin.decoration

Decoration {
    id: root
    alpha: true

    readonly property color red: "#ff2a4f"
    readonly property color redDim: "#7a1830"
    readonly property color hot: "#ffb3c0"
    readonly property color navy: "#0d1822"
    readonly property color navyLight: "#132433"
    readonly property color cyan: "#5beedc"

    readonly property bool active: decoration.client.active
    readonly property bool maxed: decoration.client.maximized
    readonly property int pad: maxed ? 0 : 18          // glow area (= KWin shadow)
    readonly property int titleH: 28
    readonly property int side: maxed ? 0 : 3
    readonly property int bottomB: maxed ? 0 : 5
    readonly property int cut: maxed ? 0 : 20
    readonly property int brCut: maxed ? 0 : 12
    property int buttonSize: 20

    // frame rectangle inside the glow padding
    readonly property real fx0: pad
    readonly property real fy0: pad
    readonly property real fx1: width - pad
    readonly property real fy1: height - pad

    DecorationOptions { id: options; deco: decoration }

    // power-on level of the glow (animated on focus changes)
    property real glow: active ? 1 : 0
    onActiveChanged: if (active) powerOn.restart(); else { powerOn.stop(); glow = 0 }
    SequentialAnimation {
        id: powerOn
        NumberAnimation { target: root; property: "glow"; from: 0; to: 1; duration: 70 }
        NumberAnimation { target: root; property: "glow"; to: 0.25; duration: 60 }
        NumberAnimation { target: root; property: "glow"; to: 1; duration: 60 }
        PauseAnimation { duration: 90 }
        NumberAnimation { target: root; property: "glow"; to: 0.6; duration: 40 }
        NumberAnimation { target: root; property: "glow"; to: 1; duration: 90 }
    }

    // ------------------------------------------------------------ body: titlebar + borders (opaque navy)
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.navy
            strokeWidth: -1
            fillRule: ShapePath.OddEvenFill
            startX: root.fx0 + root.cut; startY: root.fy0
            PathLine { x: root.fx1; y: root.fy0 }
            PathLine { x: root.fx1; y: root.fy1 - root.brCut }
            PathLine { x: root.fx1 - root.brCut; y: root.fy1 }
            PathLine { x: root.fx0; y: root.fy1 }
            PathLine { x: root.fx0; y: root.fy0 + root.cut }
            PathLine { x: root.fx0 + root.cut; y: root.fy0 }
            PathMove { x: root.fx0 + root.side; y: root.fy0 + root.titleH }
            PathLine { x: root.fx1 - root.side; y: root.fy0 + root.titleH }
            PathLine { x: root.fx1 - root.side; y: root.fy1 - root.bottomB }
            PathLine { x: root.fx0 + root.side; y: root.fy1 - root.bottomB }
            PathLine { x: root.fx0 + root.side; y: root.fy0 + root.titleH }
        }
    }

    // subtle horizontal scan texture + separator line under the titlebar
    Item {
        x: root.fx0 + root.cut; y: root.fy0; width: root.fx1 - root.fx0 - root.cut; height: root.titleH
        clip: true
        Repeater {
            model: Math.ceil(root.titleH / 3)
            Rectangle { y: index * 3; width: parent.width; height: 1; color: Qt.rgba(0.36, 0.93, 0.86, 0.035) }
        }
    }
    Rectangle {
        x: root.fx0 + root.side; y: root.fy0 + root.titleH - 1
        width: root.fx1 - root.fx0 - 2 * root.side; height: 1
        color: Qt.rgba(0.36, 0.93, 0.86, root.active ? 0.45 : 0.15)
    }

    // ------------------------------------------------------------ neon tube outline (source of the glow)
    Item {
        id: tube
        anchors.fill: parent
        visible: false
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {   // the tube
                fillColor: "transparent"
                strokeColor: root.active ? root.red : root.redDim
                strokeWidth: 2.5
                joinStyle: ShapePath.MiterJoin
                startX: root.fx0 + root.cut; startY: root.fy0 + 1.25
                PathLine { x: root.fx1 - 1.25; y: root.fy0 + 1.25 }
                PathLine { x: root.fx1 - 1.25; y: root.fy1 - root.brCut }
                PathLine { x: root.fx1 - root.brCut; y: root.fy1 - 1.25 }
                PathLine { x: root.fx0 + 1.25; y: root.fy1 - 1.25 }
                PathLine { x: root.fx0 + 1.25; y: root.fy0 + root.cut }
                PathLine { x: root.fx0 + root.cut; y: root.fy0 + 1.25 }
            }
            ShapePath {   // hot core of the tube
                fillColor: "transparent"
                strokeColor: root.active ? Qt.rgba(1, 0.75, 0.8, 0.85) : "transparent"
                strokeWidth: 0.8
                joinStyle: ShapePath.MiterJoin
                startX: root.fx0 + root.cut; startY: root.fy0 + 1.25
                PathLine { x: root.fx1 - 1.25; y: root.fy0 + 1.25 }
                PathLine { x: root.fx1 - 1.25; y: root.fy1 - root.brCut }
                PathLine { x: root.fx1 - root.brCut; y: root.fy1 - 1.25 }
                PathLine { x: root.fx0 + 1.25; y: root.fy1 - 1.25 }
                PathLine { x: root.fx0 + 1.25; y: root.fy0 + root.cut }
                PathLine { x: root.fx0 + root.cut; y: root.fy0 + 1.25 }
            }
        }
        // header tab with the HUD ticks
        Shape {
            visible: !root.maxed
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: root.active ? root.red : root.redDim
                strokeWidth: -1
                startX: root.fx0 + root.cut; startY: root.fy0
                PathLine { x: root.fx0 + root.cut + 58; y: root.fy0 }
                PathLine { x: root.fx0 + root.cut + 48; y: root.fy0 + 10 }
                PathLine { x: root.fx0 + 10; y: root.fy0 + 10 }
                PathLine { x: root.fx0 + root.cut - 10 + 10; y: root.fy0 }
            }
        }
    }
    MultiEffect {   // tube + real blurred neon glow
        source: tube
        anchors.fill: tube
        shadowEnabled: !root.maxed && root.glow > 0
        shadowColor: root.red
        shadowBlur: 1.0
        blurMax: 22
        shadowScale: 1.0
        shadowOpacity: 0.95 * root.glow
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        autoPaddingEnabled: false
        paddingRect: Qt.rect(0, 0, 0, 0)
    }
    Row {   // HUD ticks on the tab
        visible: !root.maxed
        x: root.fx0 + root.cut + 8; y: root.fy0 + 3
        spacing: 3
        Repeater { model: 3; Rectangle { width: 4; height: 4; color: root.navy } }
    }

    // cyan status segment + ID tag on the bottom border
    Rectangle {
        visible: !root.maxed
        x: root.fx0 + 18; y: root.fy1 - 4
        width: 40; height: 2
        color: root.active ? root.cyan : Qt.rgba(0.36, 0.93, 0.86, 0.3)
    }

    // ------------------------------------------------------------ title row
    Item {
        id: titleRow
        x: root.maxed ? 8 : root.fx0 + root.cut + 4
        y: root.fy0 + (root.maxed ? 0 : 2)
        width: (root.maxed ? root.width - 12 : root.fx1 - root.side - 4) - x
        height: root.titleH - (root.maxed ? 0 : 2)

        Text {
            id: caption
            anchors.left: parent.left
            anchors.leftMargin: root.maxed ? 0 : 64
            anchors.right: rightButtons.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.maxed ? 0 : 2
            text: decoration.client.caption
            textFormat: Text.PlainText
            color: root.active ? root.cyan : Qt.rgba(0.36, 0.93, 0.86, 0.5)
            font.family: "Chakra Petch"
            font.bold: true
            font.pixelSize: 13
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1.6
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }

        ButtonGroup {
            id: leftButtons
            visible: false
            spacing: 6
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
            anchors.topMargin: (titleRow.height - root.buttonSize) / 2 + (root.maxed ? 0 : 1)
            spacing: 6
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

    // cyan sweep across the titlebar on focus-in
    Item {
        x: root.fx0; y: root.fy0; width: root.fx1 - root.fx0; height: root.titleH
        clip: true
        Rectangle {
            id: sweep
            width: 120; height: parent.height; x: -width
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(0.36, 0.93, 0.86, 0) }
                GradientStop { position: 0.85; color: Qt.rgba(0.36, 0.93, 0.86, 0.22) }
                GradientStop { position: 1; color: Qt.rgba(0.36, 0.93, 0.86, 0.0) }
            }
            NumberAnimation on x { id: sweepAnim; running: false; duration: 520; easing.type: Easing.OutCubic }
        }
        Connections {
            target: root
            function onActiveChanged() {
                if (root.active) { sweepAnim.from = -sweep.width; sweepAnim.to = sweep.parent.width; sweepAnim.restart() }
            }
        }
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
        borders.setBorders(3)
        borders.setTitle(titleH)
        borders.bottom = 5
        maximizedBorders.setBorders(0)
        maximizedBorders.setTitle(titleH)
        extendedBorders.setAllBorders(5)       // easier resizing
        padding.setAllBorders(18)              // neon glow -> window shadow
    }
    Component.onCompleted: applyBorders()
}
