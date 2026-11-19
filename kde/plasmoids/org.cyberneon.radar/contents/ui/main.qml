// CyberNeon Radar - top-right HUD block for Plasma 6 (X11 and Wayland). Original artwork.
// A threat radar: contacts are programs, the heavier the closer to the centre (cyan, yellow, red), lit up by the sweep
// as it passes. Arrows on the rim are programs moving data (inward = download), a blinking red diamond is an intrusion
// event (new USB device, wrong password, SSH login, new open port, new device on the network). The dial still tells
// the time: red notch = hour, cyan notch = minute, the sweep = seconds. Data from bin/cn-threats (program names only).
// Quickhack: a click on a contact opens a panel to close that program (OVERLOAD) or force it (FLATLINE), always after
// a confirmation. The desktop session and other users' processes are protected.
// Below it, the objective tracker: the active window is the current objective, the other open windows sub-objectives.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import "cnconfig.js" as Cfg

PlasmoidItem {
    id: root
    readonly property color cy: "#5beedc"
    readonly property color red: "#ff2a4f"
    readonly property color amber: "#ffc233"
    readonly property color navy: "#0b1620"
    readonly property real minRate: 10240
    property date now: new Date()
    property real secs: 0

    // threat data
    property var hostiles: []
    property var traffic: []
    property var events: []            // newest first: {t, text, bearing, clock}
    property int seq: 0
    readonly property string tool: 'python3 -I -S "$HOME/.local/share/cyberneon/bin/cn-threats"'
    readonly property var arrows: {
        const out = [];
        for (const t of traffic) {
            if (t.down >= minRate) out.push({ b: t.bearing - 4, rate: t.down, inward: true });
            if (t.up >= minRate) out.push({ b: t.bearing + 4, rate: t.up, inward: false });
        }
        return out;
    }
    readonly property var alarms: events.filter(e => now.getTime() - e.t < 60000)
    readonly property var lastEvent: events.length && now.getTime() - events[0].t < 300000 ? events[0] : null
    readonly property bool blinkOn: power.lowPower || (secs * 2) % 1 < 0.6

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    CyberNeonPower { id: power }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { root.now = new Date(); if (power.lowPower) root.secs = root.now.getSeconds() }
    }
    FrameAnimation {    // smooth sweep (one step per second on low battery)
        running: !power.lowPower
        onTriggered: { const d = new Date(); root.secs = d.getSeconds() + d.getMilliseconds() / 1000 }
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            if (source.indexOf("--auth") >= 0) {
                try { root.addEvent(JSON.parse(data.stdout || "")) } catch (e) {}
                authPoll.restart();
            } else if (source.indexOf("--quickhack") >= 0) {
                root.readHack(data.stdout || "");
            } else if (source.indexOf("cn-threats") >= 0) {
                root.readSnap(data.stdout || "");
            }
        }
    }
    Timer {   // one scan every 4 s, every 15 s on low battery
        id: scanTimer
        interval: power.lowPower ? 15000 : 4000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: exec.connectSource(root.tool + (Cfg.SENTINEL ? "" : " --no-sentinel") + " #" + (++root.seq))
    }
    Timer {   // login events: a long poll that returns at the first one
        id: authPoll
        interval: 500; running: Cfg.SENTINEL
        onTriggered: exec.connectSource(root.tool + " --auth #" + (++root.seq))
    }
    function readSnap(out) {
        let s;
        try { s = JSON.parse(out) } catch (e) { return }
        hostiles = s.hostiles || [];
        traffic = s.traffic || [];
        for (const e of (s.events || [])) addEvent(e);
    }
    function addEvent(e) {
        if (!e || !e.text) return;
        const t = Date.now();
        if (events.some(x => x.text === e.text && t - x.t < 30000)) return;
        events = [{ t: t, text: e.text, kind: e.kind, bearing: e.bearing, clock: Qt.formatTime(new Date(), "HH:mm") }].concat(events).slice(0, 4);
        if (Cfg.SOUND_FX) exec.connectSource('"$HOME/.local/share/cyberneon/bin/cn-sfx" dialog-warning #' + (++seq));
    }
    function levelColor(l) { return l === 2 ? red : l === 1 ? amber : cy }
    function rate(b) {
        if (b >= 1048576) return (b / 1048576).toFixed(1) + "M";
        if (b >= 1024) return (b / 1024).toFixed(0) + "K";
        return b.toFixed(0) + "B";
    }
    function metric(h) {     // what makes a contact heavy: CPU (percent of one core, as in top) or memory
        if (h.cpu / 100 >= h.mem / 30) return h.cpu.toFixed(0) + "%";
        return h.rss >= 1073741824 ? (h.rss / 1073741824).toFixed(1) + "G" : (h.rss / 1048576).toFixed(0) + "M";
    }
    function netLine() {
        let d = null, u = null;
        for (const t of traffic) {
            if (t.down >= minRate && (!d || t.down > d.down)) d = t;
            if (t.up >= minRate && (!u || t.up > u.up)) u = t;
        }
        const parts = [];
        if (d) parts.push("▼ " + d.name.toUpperCase().slice(0, 12) + " " + rate(d.down) + "/s");
        if (u) parts.push("▲ " + u.name.toUpperCase().slice(0, 12) + " " + rate(u.up) + "/s");
        return parts.join("   ");
    }

    // ------------------------------------------------ quickhack
    readonly property var hacks: ({
        overload: { label: "OVERLOAD", hint: "close it, it can still save", tint: "#5beedc", force: false },
        flatline: { label: "FLATLINE", hint: "kill it, unsaved data is lost", tint: "#ff2a4f", force: true }
    })
    property var hack: null            // {name, metric, level, procs, stage, action, result}
    property string hoverName: ""
    property real uploadProgress: 0
    function openHack(h) {
        if (!Cfg.QUICKHACK) return;
        hack = { name: h.name, metric: metric(h), level: h.level, procs: h.procs || 1,
                 stage: h.protected ? "protected" : "menu", action: "", result: "" };
        hackDone.stop(); hackExpire.restart();
    }
    function setStage(stage, extra) {
        const h = Object.assign({}, hack, extra || {});
        h.stage = stage; hack = h;
    }
    function closeHack() { hack = null; hackExpire.stop(); hackDone.stop() }
    function hackAction(key) {
        if (!hack) return;
        if (key === "cancel" || key === "abort" || key === "close") closeHack();
        else if (hacks[key] && hack.stage === "menu") { setStage("confirm", { action: key }); hackExpire.restart() }
        else if (key === "upload" && hack.stage === "confirm") {
            setStage("upload"); hackExpire.stop(); uploadAnim.restart(); uploadTimer.restart();
        }
    }
    function readHack(out) {
        if (!hack) return;
        let r;
        try { r = JSON.parse(out) } catch (e) { r = { signalled: 0, refused: "TARGET LOST" } }
        const n = r.signalled || 0;
        setStage("done", { result: r.refused ? "ACCESS DENIED  //  " + r.refused
                                             : hacks[hack.action].label + " UPLOADED  //  " + n + (n === 1 ? " PROCESS" : " PROCESSES") + " HIT" });
        hackDone.restart(); scanTimer.restart();
    }
    Timer { id: hackExpire; interval: 12000; onTriggered: root.closeHack() }
    Timer { id: hackDone; interval: 3000; onTriggered: root.closeHack() }
    Timer {   // the upload bar fills, then the quickhack runs (program names only contain [A-Za-z0-9._+-])
        id: uploadTimer; interval: 900
        onTriggered: if (root.hack) exec.connectSource(root.tool + " --quickhack " + root.hack.name
                                                        + (root.hacks[root.hack.action].force ? " --force" : "") + " #" + (++root.seq))
    }
    NumberAnimation { id: uploadAnim; target: root; property: "uploadProgress"; from: 0; to: 1; duration: 900 }
    Timer {   // test lab only (LAB_QUICKHACK in cnconfig.js): runs a quickhack on the "icebreaker" contact by itself
        interval: 2500; repeat: true; running: Cfg.LAB_QUICKHACK === true
        property int step: 0
        onTriggered: {
            const t = root.hostiles.find(h => h.name === "icebreaker");
            if (step === 0 && t) { root.openHack(t); step = 1 }
            else if (step === 1) { root.hackAction("overload"); step = 2 }
            else if (step === 2) { root.hackAction("upload"); step = 3 }
            else if (step === 3) running = false;
        }
    }

    TaskManager.VirtualDesktopInfo { id: vdInfo }
    TaskManager.ActivityInfo { id: actInfo }
    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortLastActivated
        filterByVirtualDesktop: true
        filterByActivity: true
        virtualDesktop: vdInfo.currentDesktop
        activity: actInfo.currentActivity
    }

    // a triangle on the rim pointing at the centre (the time)
    component Notch: Item {      // fills the radar; an inline component cannot see the ids of this file
        id: notch
        property real angle: 0
        property real len: 12
        property real half: 4.5
        property color color: "#5beedc"
        readonly property real r: width / 2
        anchors.fill: parent; rotation: angle
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1; fillColor: notch.color
                startX: notch.r; startY: 1 + notch.len
                PathLine { x: notch.r - notch.half; y: 1 }
                PathLine { x: notch.r + notch.half; y: 1 }
                PathLine { x: notch.r; y: 1 + notch.len }
            }
        }
    }

    component HackButton: Item {   // a quickhack button with a cut corner
        id: hb
        property string label
        property color tint: "#5beedc"
        property bool filled: false
        signal activated()
        height: 28
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: hb.tint; strokeWidth: 1.5
                fillColor: Qt.rgba(hb.tint.r, hb.tint.g, hb.tint.b, hb.filled ? 0.9 : 0.12)
                startX: 6; startY: 0
                PathLine { x: hb.width; y: 0 }
                PathLine { x: hb.width; y: 22 }
                PathLine { x: hb.width - 6; y: 28 }
                PathLine { x: 0; y: 28 }
                PathLine { x: 0; y: 6 }
                PathLine { x: 6; y: 0 }
            }
        }
        Text {
            anchors.centerIn: parent; text: hb.label; color: hb.filled ? "#0b1620" : hb.tint
            font.family: "Rajdhani"; font.bold: true; font.pixelSize: 14; font.letterSpacing: 2
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hb.activated() }
    }

    fullRepresentation: Item {
        implicitWidth: 340
        implicitHeight: 540

        Item {
            id: hud
            anchors.fill: parent
            anchors.margins: 12
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: root.cy; shadowBlur: 0.6; blurMax: 16
                                        shadowOpacity: 0.6; shadowHorizontalOffset: 0; shadowVerticalOffset: 0; autoPaddingEnabled: true }

            // ------------------------------------------------ radar
            Item {
                id: radar
                anchors.right: parent.right
                width: 240; height: 240
                readonly property real r: width / 2

                Rectangle { anchors.fill: parent; radius: width / 2; color: Qt.rgba(0.043, 0.086, 0.125, 0.55)
                            border.color: Qt.rgba(0.36, 0.93, 0.86, 0.85); border.width: 1.5 }
                Rectangle { anchors.centerIn: parent; width: parent.width * 0.62; height: width; radius: width / 2
                            color: "transparent"; border.color: Qt.rgba(0.36, 0.93, 0.86, 0.25); border.width: 1 }
                Rectangle { anchors.centerIn: parent; width: parent.width * 0.3; height: width; radius: width / 2
                            color: "transparent"; border.color: Qt.rgba(0.36, 0.93, 0.86, 0.2); border.width: 1 }
                Repeater {   // 60 ticks
                    model: 60
                    Rectangle {
                        required property int index
                        x: radar.r - width / 2; y: 3
                        width: index % 5 === 0 ? 2 : 1; height: index % 5 === 0 ? 10 : 5
                        color: index % 15 === 0 ? root.red : Qt.rgba(0.36, 0.93, 0.86, 0.7)
                        transform: Rotation { origin.x: width / 2; origin.y: radar.r - 3; angle: index * 6 }
                    }
                }
                Repeater {   // second labels at the quarter ticks
                    model: ["00", "15", "30", "45"]
                    Text {
                        required property int index
                        required property string modelData
                        readonly property real a: index * Math.PI / 2
                        x: radar.r + Math.sin(a) * (radar.r - 24) - width / 2
                        y: radar.r - Math.cos(a) * (radar.r - 24) - height / 2
                        text: modelData; color: Qt.rgba(0.36, 0.93, 0.86, 0.7)
                        font.family: "Rajdhani"; font.bold: true; font.pixelSize: 11
                    }
                }
                Notch { angle: ((root.now.getHours() % 12) + root.now.getMinutes() / 60) * 30; len: 16; half: 7; color: root.red }
                Notch { angle: root.now.getMinutes() * 6 + root.now.getSeconds() / 10; len: 12; half: 4.5; color: root.cy }
                Kirigami.Icon {
                    anchors.centerIn: parent; width: 34; height: 34
                    source: "cyberneon-launcher"; fallback: "cyberneon-logo"
                }
                Repeater {   // traffic arrows, at the program's bearing
                    model: root.arrows
                    Item {
                        id: arrow
                        required property var modelData
                        readonly property real len: Math.min(34, 10 + 8 * Math.log10(Math.max(1, modelData.rate / root.minRate)))
                        readonly property real outer: 16
                        readonly property real inner: 16 + len
                        readonly property real tip: modelData.inward ? inner : outer
                        readonly property real dir: modelData.inward ? 1 : -1
                        width: radar.width; height: radar.height; rotation: modelData.b
                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: Qt.rgba(0.36, 0.93, 0.86, arrow.modelData.inward ? 1 : 0.75); strokeWidth: 2
                                fillColor: "transparent"
                                startX: radar.r; startY: arrow.modelData.inward ? arrow.outer : arrow.inner
                                PathLine { x: radar.r; y: arrow.tip - arrow.dir * 4 }
                            }
                            ShapePath {
                                strokeWidth: -1; fillColor: Qt.rgba(0.36, 0.93, 0.86, arrow.modelData.inward ? 1 : 0.75)
                                startX: radar.r; startY: arrow.tip
                                PathLine { x: radar.r - 4.5; y: arrow.tip - arrow.dir * 7 }
                                PathLine { x: radar.r + 4.5; y: arrow.tip - arrow.dir * 7 }
                                PathLine { x: radar.r; y: arrow.tip }
                            }
                        }
                    }
                }
                Shape {   // sweep wedge
                    anchors.fill: parent
                    rotation: root.secs * 6
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeWidth: -1
                        fillGradient: ConicalGradient {
                            centerX: radar.r; centerY: radar.r; angle: 90
                            GradientStop { position: 0.0; color: Qt.rgba(0.36, 0.93, 0.86, 0.45) }
                            GradientStop { position: 0.12; color: Qt.rgba(0.36, 0.93, 0.86, 0.0) }
                            GradientStop { position: 1.0; color: Qt.rgba(0.36, 0.93, 0.86, 0.0) }
                        }
                        startX: radar.r; startY: radar.r
                        PathAngleArc { centerX: radar.r; centerY: radar.r; radiusX: radar.r - 2; radiusY: radar.r - 2; startAngle: -90; sweepAngle: -44 }
                        PathLine { x: radar.r; y: radar.r }
                    }
                    ShapePath {
                        strokeColor: root.cy; strokeWidth: 1.5
                        startX: radar.r; startY: radar.r
                        PathLine { x: radar.r; y: 2 }
                    }
                }
                Repeater {   // contacts: they glow when the sweep passes and fade like phosphor
                    model: root.hostiles
                    Item {
                        id: blip
                        required property int index
                        required property var modelData
                        readonly property real k: Math.min(1, Math.max(0, (modelData.score - 0.2) / 0.8))
                        readonly property real dist: radar.r * (0.88 - 0.6 * k)     // the closest stays clear of the logo
                        readonly property real a: modelData.bearing * Math.PI / 180
                        readonly property color c: root.levelColor(modelData.level)
                        readonly property real size: 3.5 + 3.5 * Math.min(1, modelData.mem / 20)
                        readonly property real glow: Math.max(0, 1 - ((((root.secs * 6 - modelData.bearing) % 360) + 360) % 360) / 140)
                        x: radar.r + Math.sin(a) * dist; y: radar.r - Math.cos(a) * dist
                        Rectangle {   // ping ring right after the hit
                            readonly property real rr: blip.size + 3 + (1 - blip.glow) * 28
                            visible: blip.glow > 0.75
                            x: -rr; y: -rr; width: 2 * rr; height: width; radius: rr
                            color: "transparent"; border.color: blip.c; border.width: 1.5; opacity: (blip.glow - 0.75) * 3
                        }
                        Rectangle {
                            x: -width / 2; y: -height / 2; width: 2 * (blip.size + 3); height: width; radius: width / 2
                            color: blip.c; opacity: 0.18 * (0.3 + 0.7 * blip.glow)
                        }
                        Rectangle {
                            x: -blip.size; y: -blip.size; width: 2 * blip.size; height: width; radius: blip.size
                            color: blip.c; opacity: 0.3 + 0.7 * blip.glow
                        }
                        MouseArea {   // quickhack target
                            x: -14; y: -14; width: 28; height: 28
                            enabled: Cfg.QUICKHACK; hoverEnabled: true; cursorShape: Qt.CrossCursor
                            onContainsMouseChanged: root.hoverName = containsMouse ? blip.modelData.name
                                                    : (root.hoverName === blip.modelData.name ? "" : root.hoverName)
                            onClicked: root.openHack(blip.modelData)
                        }
                        Repeater {    // targeting brackets on the contact under the mouse or under a quickhack
                            model: (root.hack ? root.hack.name : root.hoverName) === blip.modelData.name ? 4 : 0
                            Item {
                                required property int index
                                readonly property int sx: index === 0 || index === 3 ? -1 : 1
                                readonly property int sy: index < 2 ? -1 : 1
                                readonly property color tint: root.hack ? root.red : root.cy
                                Rectangle { x: parent.sx < 0 ? -13 : 6; y: parent.sy < 0 ? -13 : 11; width: 7; height: 2; color: parent.tint }
                                Rectangle { x: parent.sx < 0 ? -13 : 11; y: parent.sy < 0 ? -13 : 6; width: 2; height: 7; color: parent.tint }
                            }
                        }
                        Text {   // the name of the heaviest contact and of every yellow or red one
                            visible: blip.modelData.level >= 1 || blip.index === 0
                            x: blip.x > radar.r ? -blip.size - 6 - width : blip.size + 6
                            y: -height / 2
                            text: blip.modelData.name.toUpperCase().slice(0, 12) + " " + root.metric(blip.modelData)
                            color: blip.c
                            font.family: "Rajdhani"; font.bold: true; font.pixelSize: 12; font.letterSpacing: 1
                        }
                    }
                }
                Repeater {   // intrusion events blink on the rim for a minute
                    model: root.alarms
                    Item {
                        required property var modelData
                        readonly property real a: modelData.bearing * Math.PI / 180
                        x: radar.r + Math.sin(a) * (radar.r - 30); y: radar.r - Math.cos(a) * (radar.r - 30)
                        opacity: root.blinkOn ? 1 : 0.2
                        Rectangle { x: -6; y: -6; width: 12; height: 12; rotation: 45; color: Qt.rgba(1, 0.165, 0.31, 0.25)
                                    border.color: root.red; border.width: 2 }
                        Rectangle { x: -2; y: -2; width: 4; height: 4; radius: 2; color: root.red }
                        Text {
                            x: -width / 2; y: 9
                            text: String(parent.modelData.kind || "").toUpperCase()
                            color: root.red; font.family: "Rajdhani"; font.bold: true; font.pixelSize: 10; font.letterSpacing: 1
                        }
                    }
                }
            }

            // ------------------------------------------------ status: heaviest contact, who moves data, last intrusion
            Column {
                id: status
                anchors.right: radar.right
                anchors.top: radar.bottom; anchors.topMargin: 8
                spacing: 6
                Text {
                    anchors.right: parent.right
                    readonly property var lead: root.hostiles.length ? root.hostiles[0] : null
                    text: lead ? "HOSTILES " + String(root.hostiles.length).padStart(2, "0") + "  //  "
                                 + lead.name.toUpperCase().slice(0, 14) + " " + root.metric(lead)
                               : "ZONE CLEAR  //  NO HOSTILES"
                    color: lead ? root.levelColor(lead.level) : root.cy
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 15; font.letterSpacing: 2
                }
                Text {
                    anchors.right: parent.right
                    readonly property string line: root.netLine()
                    width: Math.min(implicitWidth, hud.width - 8); elide: Text.ElideLeft; horizontalAlignment: Text.AlignRight
                    text: line || "NET  //  QUIET"
                    color: root.cy; opacity: line ? 1 : 0.6
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 13; font.letterSpacing: 2
                }
                Text {
                    anchors.right: parent.right
                    visible: root.lastEvent !== null
                    width: Math.min(implicitWidth, hud.width - 8); elide: Text.ElideLeft; horizontalAlignment: Text.AlignRight
                    text: root.lastEvent ? "!! " + root.lastEvent.text + "  " + root.lastEvent.clock : ""
                    color: root.red
                    opacity: root.lastEvent && root.now.getTime() - root.lastEvent.t < 60000 ? 1 : 0.6
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 12; font.letterSpacing: 1
                }
            }

            // ------------------------------------------------ quickhack panel (over the status lines)
            Item {
                id: hackPanel
                visible: root.hack !== null
                z: 10
                anchors.right: parent.right
                anchors.top: radar.bottom; anchors.topMargin: 4
                width: hud.width; height: 152
                readonly property var h: root.hack || ({ name: "", metric: "", level: 0, procs: 1, stage: "", action: "", result: "" })
                readonly property var act: root.hacks[h.action] || root.hacks.overload
                readonly property color tint: root.levelColor(h.level)
                MouseArea { anchors.fill: parent }          // the panel takes the clicks that fall on it
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: root.red; strokeWidth: 1.5; fillColor: Qt.rgba(0.043, 0.086, 0.125, 0.96)
                        startX: 12; startY: 0.75
                        PathLine { x: hackPanel.width - 0.75; y: 0.75 }
                        PathLine { x: hackPanel.width - 0.75; y: hackPanel.height - 12 }
                        PathLine { x: hackPanel.width - 12; y: hackPanel.height - 0.75 }
                        PathLine { x: 0.75; y: hackPanel.height - 0.75 }
                        PathLine { x: 0.75; y: 12 }
                        PathLine { x: 12; y: 0.75 }
                    }
                    ShapePath {
                        strokeWidth: -1; fillColor: root.red
                        startX: 12; startY: 0
                        PathLine { x: 150; y: 0 }
                        PathLine { x: 136; y: 16 }
                        PathLine { x: 0; y: 16 }
                        PathLine { x: 0; y: 12 }
                        PathLine { x: 12; y: 0 }
                    }
                }
                Text { x: 14; y: 1; text: "QUICKHACK // TARGET"; color: root.navy; font.family: "Rajdhani"; font.bold: true; font.pixelSize: 10; font.letterSpacing: 1 }
                Text {
                    x: 14; y: 20; width: hackPanel.width - 110; elide: Text.ElideRight
                    text: hackPanel.h.name.toUpperCase(); color: hackPanel.tint
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 22; font.letterSpacing: 2
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 12; y: 24
                    text: hackPanel.h.metric; color: hackPanel.tint; font.family: "Orbitron"; font.bold: true; font.pixelSize: 15
                }
                Text {
                    x: 14; y: 50; visible: hackPanel.h.stage === "menu" || hackPanel.h.stage === "protected"
                    text: hackPanel.h.procs + (hackPanel.h.procs === 1 ? " PROCESS" : " PROCESSES") + (hackPanel.h.stage === "protected" ? "  //  PROTECTED" : "")
                    color: Qt.rgba(0.49, 0.87, 0.84, 0.8); font.family: "Rajdhani"; font.bold: true; font.pixelSize: 12; font.letterSpacing: 2
                }
                // protected: system or another user
                Text {
                    x: 14; y: 76; visible: hackPanel.h.stage === "protected"
                    text: "SYSTEM OR ANOTHER USER: NO QUICKHACK"; color: root.red
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 13; font.letterSpacing: 1
                }
                HackButton {
                    visible: hackPanel.h.stage === "protected"
                    x: hackPanel.width - 104; y: hackPanel.height - 42; width: 90; label: "CLOSE"
                    onActivated: root.hackAction("close")
                }
                // menu: the two quickhacks
                Repeater {
                    model: hackPanel.h.stage === "menu" ? ["overload", "flatline"] : []
                    Item {
                        required property int index
                        required property string modelData
                        x: 14; y: 72 + index * 36; width: hackPanel.width - 28; height: 28
                        HackButton { width: 112; label: root.hacks[parent.modelData].label; tint: root.hacks[parent.modelData].tint
                                     onActivated: root.hackAction(parent.modelData) }
                        Text {
                            x: 122; y: 6; width: parent.width - 122; elide: Text.ElideRight
                            text: root.hacks[parent.modelData].hint; color: Qt.rgba(0.49, 0.87, 0.84, 0.85)
                            font.family: "Rajdhani"; font.bold: true; font.pixelSize: 12
                        }
                    }
                }
                HackButton {
                    visible: hackPanel.h.stage === "menu"
                    x: hackPanel.width - 76; y: 44; width: 62; label: "X"; tint: "#7dded6"
                    onActivated: root.hackAction("cancel")
                }
                // confirm
                Text {
                    x: 14; y: 52; width: hackPanel.width - 28; elide: Text.ElideRight
                    visible: hackPanel.h.stage === "confirm" || hackPanel.h.stage === "upload"
                    text: hackPanel.h.stage === "upload" ? "UPLOADING " + hackPanel.act.label + "..."
                                                          : "UPLOAD " + hackPanel.act.label + " TO " + hackPanel.h.name.toUpperCase().slice(0, 14) + "?"
                    color: hackPanel.act.tint; font.family: "Rajdhani"; font.bold: true; font.pixelSize: 15; font.letterSpacing: 2
                }
                Text {
                    x: 14; y: 76; visible: hackPanel.h.stage === "confirm"
                    text: hackPanel.act.hint; color: Qt.rgba(0.49, 0.87, 0.84, 0.85)
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 12
                }
                HackButton {
                    visible: hackPanel.h.stage === "confirm"
                    x: 14; y: hackPanel.height - 42; width: 130; label: "UPLOAD"; tint: hackPanel.act.tint; filled: true
                    onActivated: root.hackAction("upload")
                }
                HackButton {
                    visible: hackPanel.h.stage === "confirm"
                    x: 156; y: hackPanel.height - 42; width: 100; label: "ABORT"; tint: "#7dded6"
                    onActivated: root.hackAction("abort")
                }
                // upload bar
                Repeater {
                    model: hackPanel.h.stage === "upload" ? 30 : 0
                    Rectangle {
                        required property int index
                        x: 14 + index * 9.6; y: 84; width: 7.6; height: 18
                        readonly property bool lit: index < Math.round(root.uploadProgress * 30)
                        color: lit ? hackPanel.act.tint : Qt.rgba(0.36, 0.93, 0.86, 0.12)
                    }
                }
                // result
                Text {
                    x: 14; y: 58; width: hackPanel.width - 28; elide: Text.ElideRight
                    visible: hackPanel.h.stage === "done"
                    text: hackPanel.h.result
                    color: hackPanel.h.result.indexOf("ACCESS") === 0 ? root.red : root.cy
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 15; font.letterSpacing: 1
                }
            }

            // ------------------------------------------------ objective tracker
            Column {
                id: tracker
                anchors.right: parent.right
                anchors.top: status.bottom; anchors.topMargin: 14
                width: hud.width
                spacing: 6

                Row {
                    anchors.right: parent.right; spacing: 8
                    Text { text: "OBJECTIVE"; color: root.red; font.family: "Rajdhani"; font.bold: true; font.pixelSize: 14; font.letterSpacing: 3 }
                    Rectangle { width: 10; height: 10; rotation: 45; color: root.red; anchors.verticalCenter: parent.verticalCenter }
                }
                Repeater {
                    model: tasks
                    delegate: Row {
                        required property int index
                        required property var model
                        visible: index < 5
                        height: visible ? implicitHeight : 0
                        anchors.right: parent.right
                        layoutDirection: Qt.RightToLeft
                        spacing: 8
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: index === 0 ? 10 : 8; height: width
                            color: index === 0 ? root.cy : "transparent"
                            border.color: index === 0 ? root.cy : Qt.rgba(0.36, 0.93, 0.86, 0.6); border.width: 1.5
                        }
                        Text {
                            width: Math.min(implicitWidth, tracker.width - 24)
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignRight
                            text: (parent.model.display || "").toString()
                            color: index === 0 ? root.cy : Qt.rgba(0.49, 0.87, 0.84, 0.75)
                            font.family: "Rajdhani"; font.bold: index === 0; font.pixelSize: index === 0 ? 17 : 14
                            font.capitalization: Font.AllUppercase; font.letterSpacing: 1
                        }
                    }
                }
                Text {
                    anchors.right: parent.right
                    visible: tasks.count === 0
                    text: "NO ACTIVE GIG // STANDBY"
                    color: Qt.rgba(0.49, 0.87, 0.84, 0.7)
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 15; font.letterSpacing: 2
                }
                Text {
                    anchors.right: parent.right
                    text: "WORKSPACE " + (Math.max(0, (vdInfo.desktopIds || []).indexOf(vdInfo.currentDesktop)) + 1) + " / " + vdInfo.numberOfDesktops
                    color: Qt.rgba(1, 0.165, 0.31, 0.85)
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 12; font.letterSpacing: 3
                }
            }
        }
    }
}
