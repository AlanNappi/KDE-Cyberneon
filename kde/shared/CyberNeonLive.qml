// CyberNeon Live - the animated CyberNeon wallpaper as a reusable Qt Quick item (wallpaper plugin, SDDM, splash).
// A 1:1 port of the Budgie edition's live layer (config/live-wallpaper.py in cyberneon-budgie): same elements,
// positions, colours and timings, rendered by the GPU in sync with the display instead of 15 fps cairo frames.
// On the desktop it can also react to the system: alert (load over the limits) and terminalLines (live terminal text).
// Original artwork. FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import QtQuick.Shapes

Item {
    id: cn

    property url source            // the static CyberNeon wallpaper (3840x2160, make_wallpaper.py)
    property bool animated: true
    property bool running: true
    property bool alert: false            // overload: alarm banner, red edges, faster animation, frequent glitches
    property var terminalLines: []        // [{s: text, c: "cy"|"red", a: opacity}]; empty = the terminal painted in the image
    property url terminalPlate            // the terminal background without text (make_wallpaper.py --terminal-plate)

    // wallpaper image coordinates (3840x2160) -> item coordinates ("zoom" = scaled and cropped)
    readonly property real sc: Math.max(width / 3840, height / 2160)
    readonly property real ox: (width - 3840 * sc) / 2
    readonly property real oy: (height - 2160 * sc) / 2
    function mx(x) { return ox + x * sc }
    function my(y) { return oy + y * sc }
    function mod(a, n) { return ((a % n) + n) % n }      // Python-style modulo

    readonly property color cy: "#5beedc"
    readonly property color red: "#ff2a4f"
    readonly property var nodes: [[2820, 330], [3080, 250], [3330, 380], [3560, 280], [2950, 560], [3220, 620], [3480, 560], [3100, 860]]
    readonly property var target: [3650, 760]
    readonly property var route: [[2820, 330], [2950, 560], [3220, 620], [3480, 560], [3650, 760]]
    readonly property var sigil: [1920, 1010]
    readonly property string hex: "0123456789ABCDEF"

    // animation clock (seconds)
    property real t: 0
    FrameAnimation {
        running: cn.animated && cn.running && cn.visible
        onTriggered: cn.t += frameTime * (cn.alert ? 1.6 : 1)
    }

    Rectangle { anchors.fill: parent; color: "#070d1a" }

    Item {
        id: scene             // what the glitch slices copy: the image and the live terminal
        anchors.fill: parent

        Image {
            id: base
            anchors.fill: parent
            source: cn.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            smooth: true
        }

        // -------------------------------------------------------------- live terminal, same place and type as the image's
        Image {
            id: plate
            x: cn.mx(236); y: cn.my(384); width: 1028 * cn.sc; height: 752 * cn.sc
            source: cn.terminalLines.length > 0 ? cn.terminalPlate : ""
            visible: status === Image.Ready && base.status === Image.Ready
            asynchronous: true
            smooth: true

            Repeater {
                model: cn.terminalLines
                Text {
                    required property var modelData
                    required property int index
                    x: 28 * cn.sc
                    y: (56 + index * 56) * cn.sc - baselineOffset
                    width: plate.width - 56 * cn.sc
                    elide: Text.ElideRight
                    text: modelData.s
                    color: modelData.c === "red" ? cn.red : cn.cy
                    opacity: modelData.a
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: Math.max(9, 30 * cn.sc)
                }
            }
        }
    }

    Item {
        id: fx
        anchors.fill: parent
        visible: cn.animated && base.status === Image.Ready

        // ------------------------------------------------------------------ falling hex columns
        Timer {   // every column shifts its characters each 0.18 s
            interval: 180; repeat: true
            running: fx.visible && cn.running
            onTriggered: { for (let i = 0; i < hexCols.count; i++) hexCols.itemAt(i).shift() }
        }
        Repeater {
            id: hexCols
            model: 9
            Item {
                id: col
                required property int index
                readonly property real dur: 14 + cn.mod(index * 3.779, 9)
                readonly property real fs: Math.max(10, 24 * cn.sc)
                readonly property real colh: 18 * fs * 1.15
                property var chars: {
                    const a = [];
                    for (let k = 0; k < 18; k++) a.push(cn.hex[Math.floor(Math.random() * 16)]);
                    return a;
                }
                function shift() { const a = chars.slice(1); a.push(cn.hex[Math.floor(Math.random() * 16)]); chars = a }
                x: cn.width * cn.mod(index * 0.137 + 0.06, 1)
                y: cn.mod(cn.t / dur, 1) * (cn.height + colh) - colh
                Repeater {
                    model: 18
                    Text {
                        required property int index
                        y: index * col.fs * 1.15 - col.fs * 0.8          // cairo draws at the baseline
                        text: col.chars[index]
                        color: cn.cy
                        opacity: 0.06 + 0.25 * index / 18
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: col.fs
                    }
                }
            }
        }

        // ------------------------------------------------------------------ rotating arcs around the sigil
        Shape {
            id: redArc   // red: r 600, 7 px, 0-34 and 180-192 deg, one turn every 48 s
            readonly property real r: 600 * cn.sc
            readonly property real w: Math.max(2, 7 * cn.sc)
            width: 2 * (r + w); height: width
            x: cn.mx(cn.sigil[0]) - width / 2; y: cn.my(cn.sigil[1]) - height / 2
            rotation: cn.mod(cn.t / 48 * 360, 360)
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.rgba(1, 0.165, 0.31, 0.75); strokeWidth: redArc.w; fillColor: "transparent"; capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: redArc.width / 2; centerY: redArc.height / 2; radiusX: redArc.r; radiusY: redArc.r; startAngle: 0; sweepAngle: 34; moveToStart: true }
                PathAngleArc { centerX: redArc.width / 2; centerY: redArc.height / 2; radiusX: redArc.r; radiusY: redArc.r; startAngle: 180; sweepAngle: 12; moveToStart: true }
            }
        }
        Shape {
            id: cyanArc   // cyan dashed: r 650, 3 px, 20-90 and 200-245 deg, counter-rotating every 30 s
            readonly property real r: 650 * cn.sc
            readonly property real w: Math.max(1, 3 * cn.sc)
            width: 2 * (r + w); height: width
            x: cn.mx(cn.sigil[0]) - width / 2; y: cn.my(cn.sigil[1]) - height / 2
            rotation: -cn.mod(cn.t / 30 * 360, 360)
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.rgba(0.357, 0.933, 0.863, 0.55); strokeWidth: cyanArc.w; fillColor: "transparent"
                capStyle: ShapePath.FlatCap; strokeStyle: ShapePath.DashLine
                dashPattern: [6 / cyanArc.w, 5 / cyanArc.w]
                PathAngleArc { centerX: cyanArc.width / 2; centerY: cyanArc.height / 2; radiusX: cyanArc.r; radiusY: cyanArc.r; startAngle: 20; sweepAngle: 70; moveToStart: true }
                PathAngleArc { centerX: cyanArc.width / 2; centerY: cyanArc.height / 2; radiusX: cyanArc.r; radiusY: cyanArc.r; startAngle: 200; sweepAngle: 45; moveToStart: true }
            }
        }

        // ------------------------------------------------------------------ network: blinking nodes + pulsing target
        Repeater {
            model: cn.nodes.length
            Rectangle {
                required property int index
                readonly property real period: 0.9 + cn.mod(index * 1.373, 4.2)
                readonly property real phase: cn.mod(index * 0.61, 3)
                readonly property real u: cn.mod(cn.t + phase, period + 0.82) - period
                readonly property real lw: Math.max(1, 4 * cn.sc)
                readonly property real s: 40 * cn.sc + lw                      // cairo strokes centred on the path
                width: s; height: s
                x: cn.mx(cn.nodes[index][0]) - s / 2; y: cn.my(cn.nodes[index][1]) - s / 2
                color: "transparent"; border.color: cn.cy; border.width: lw
                opacity: u < 0 ? 0 : (u < 0.12 ? 0.95 * u / 0.12 : Math.max(0, 0.95 * Math.pow(1 - (u - 0.12) / 0.7, 2)))
                visible: opacity > 0
            }
        }
        Rectangle {
            readonly property real p: cn.mod(cn.t, 1.6) / 1.6
            readonly property real k: 1 + 1.8 * (1 - Math.pow(1 - p, 3))
            readonly property real lw: Math.max(1, 4 * cn.sc)
            readonly property real s: 40 * cn.sc * k + lw
            width: s; height: s
            x: cn.mx(cn.target[0]) - s / 2; y: cn.my(cn.target[1]) - s / 2
            color: "transparent"; border.color: cn.red; border.width: lw
            opacity: Math.max(0, Math.min(1, 1.6 - k * 0.55))
        }

        // ------------------------------------------------------------------ data packets on the route
        Repeater {
            model: 3
            Rectangle {
                required property int index
                readonly property var pos: {
                    const R = cn.route; let lens = [], total = 0;
                    for (let i = 0; i < R.length - 1; i++) { const l = Math.hypot(R[i + 1][0] - R[i][0], R[i + 1][1] - R[i][1]); lens.push(l); total += l }
                    let d = cn.mod((cn.t - 1.7 * index) / 5.2, 1) * total;
                    for (let i = 0; i < lens.length; i++) {
                        if (d <= lens[i]) { const f = d / lens[i]; return [R[i][0] + (R[i + 1][0] - R[i][0]) * f, R[i][1] + (R[i + 1][1] - R[i][1]) * f] }
                        d -= lens[i];
                    }
                    return R[R.length - 1];
                }
                readonly property real q: Math.max(4, 14 * cn.sc)
                width: q; height: q
                x: cn.mx(pos[0]) - q / 2; y: cn.my(pos[1]) - q / 2
                color: index === 1 ? cn.red : cn.cy
            }
        }

        // ------------------------------------------------------------------ scan line with a soft trail (11 s)
        Item {
            width: cn.width; height: 90
            y: cn.mod(cn.t, 11) / 11 * (cn.height + 90) - 90
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(0.357, 0.933, 0.863, 0) }
                    GradientStop { position: 1; color: Qt.rgba(0.357, 0.933, 0.863, 0.07) }
                }
            }
            Rectangle { y: 88; width: parent.width; height: 2; color: Qt.rgba(0.357, 0.933, 0.863, 0.22) }
        }

        // ------------------------------------------------------------------ periodic glitch (every 7-14 s, 130 ms)
        Item {
            id: glitch
            anchors.fill: parent
            visible: false
            property int seed: 1
            property var slices: []
            property real lineY: 0
            function rnd() { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff }
            function fire() {
                const s = [];
                const n = cn.alert ? 9 : 5, spread = cn.alert ? 260 : 120;
                for (let i = 0; i < n; i++) s.push({ sy: rnd() * cn.height, sh: 4 + rnd() * 26, dx: (rnd() - 0.5) * spread });
                slices = s; lineY = rnd() * cn.height; visible = true; off.restart();
                for (let i = 0; i < sliceItems.count; i++) sliceItems.itemAt(i).scheduleUpdate();
            }
            Timer {
                id: off; interval: 130
                onTriggered: {
                    glitch.visible = false;
                    next.interval = cn.alert ? 600 + Math.random() * 1400 : 7000 + Math.random() * 7000;
                    next.restart();
                }
            }
            Timer { id: next; interval: 9000; running: fx.visible && cn.running; onTriggered: glitch.fire() }
            Connections {
                target: cn
                function onAlertChanged() { if (cn.alert && !glitch.visible) { next.interval = 300; next.restart() } }
            }
            Repeater {
                id: sliceItems
                model: glitch.slices.length
                ShaderEffectSource {   // a strip of the real wallpaper, displaced sideways
                    required property int index
                    readonly property var sl: glitch.slices[index]
                    sourceItem: scene
                    sourceRect: Qt.rect(0, sl.sy, cn.width, sl.sh)
                    x: sl.dx; y: sl.sy; width: cn.width; height: sl.sh
                    live: false
                }
            }
            Rectangle {
                y: glitch.lineY; width: cn.width; height: 3
                color: cn.alert || glitch.seed % 2 ? cn.red : cn.cy; opacity: 0.6
            }
        }

        // ------------------------------------------------------------------ alert: red screen edges + alarm banner
        Item {
            id: alarm
            anchors.fill: parent
            visible: cn.alert
            readonly property real edge: 150 * Math.max(0.5, cn.sc * 2)

            Item {
                anchors.fill: parent
                SequentialAnimation on opacity {      // about one pulse per second, well below flashing rates
                    running: alarm.visible && cn.running; loops: Animation.Infinite
                    NumberAnimation { from: 0.25; to: 1; duration: 450; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1; to: 0.25; duration: 450; easing.type: Easing.InOutSine }
                }
                Rectangle {
                    width: parent.width; height: alarm.edge
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(1, 0.165, 0.31, 0.3) }
                        GradientStop { position: 1; color: Qt.rgba(1, 0.165, 0.31, 0) }
                    }
                }
                Rectangle {
                    y: parent.height - height; width: parent.width; height: alarm.edge
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(1, 0.165, 0.31, 0) }
                        GradientStop { position: 1; color: Qt.rgba(1, 0.165, 0.31, 0.3) }
                    }
                }
                Rectangle {
                    width: alarm.edge; height: parent.height
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Qt.rgba(1, 0.165, 0.31, 0.3) }
                        GradientStop { position: 1; color: Qt.rgba(1, 0.165, 0.31, 0) }
                    }
                }
                Rectangle {
                    x: parent.width - width; width: alarm.edge; height: parent.height
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Qt.rgba(1, 0.165, 0.31, 0) }
                        GradientStop { position: 1; color: Qt.rgba(1, 0.165, 0.31, 0.3) }
                    }
                }
            }

            Rectangle {   // lights up over "!! INTRUSION COUNTERMEASURES ARMED !!" in the image
                x: cn.mx(1004); y: cn.my(1848)
                width: banner.implicitWidth + 32 * cn.sc; height: 54 * cn.sc
                color: cn.red
                SequentialAnimation on opacity {
                    running: alarm.visible && cn.running; loops: Animation.Infinite
                    NumberAnimation { to: 1; duration: 1 } PauseAnimation { duration: 420 }
                    NumberAnimation { to: 0; duration: 1 } PauseAnimation { duration: 320 }
                }
                Text {
                    id: banner
                    anchors.centerIn: parent
                    text: "!! INTRUSION COUNTERMEASURES ARMED !!"
                    color: "#070d1a"
                    font.family: "Chakra Petch"; font.bold: true; font.pixelSize: Math.max(10, 32 * cn.sc)
                }
            }
        }
    }
}
