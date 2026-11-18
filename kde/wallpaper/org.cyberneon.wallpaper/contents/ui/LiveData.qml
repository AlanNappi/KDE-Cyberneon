// CyberNeon Live data: what the desktop wallpaper reacts to (alert state, battery) and the text of its terminal.
// Loaded only inside plasmashell: the lock screen, SDDM and the splash never show live system data.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "cnconfig.js" as Cfg

Item {
    id: live
    visible: false

    readonly property bool alert: reactor.alert
    readonly property bool lowPower: power.lowPower
    property var lines: []
    property var links: []
    property var journal: []
    property int traceSeconds: 0
    property real downRate: 0
    property real upRate: 0
    readonly property bool tracing: Math.max(downRate, upRate) >= Cfg.TRACE_MBPS * 1000000
    property int seq: 0

    CyberNeonPower { id: power }
    CyberNeonReactor { id: reactor }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => { disconnectSource(source); live.parse(data.stdout || "") }
    }
    Timer {
        interval: 5000; repeat: true; triggeredOnStart: true
        running: Cfg.LIVE_TERMINAL && Cfg.TERMINAL_PLATE !== "" && !power.lowPower
        onTriggered: exec.connectSource('"$HOME/.local/share/cyberneon/bin/cn-netlog" #' + (++live.seq))
    }
    Timer {
        interval: 1000; repeat: true
        running: Cfg.LIVE_TERMINAL && live.tracing && !power.lowPower
        onRunningChanged: if (!running) { live.traceSeconds = 0; live.build() }
        onTriggered: { live.traceSeconds++; live.build() }
    }
    Connections { target: reactor; function onAlertChanged() { live.build() } }

    function parse(out) {
        const c = [], j = [];
        for (const row of out.split("\n")) {
            const f = row.split("|");
            if (f[0] === "C" && f.length === 5) c.push(f);
            else if (f[0] === "J" && f.length === 5) j.push(f);
            else if (f[0] === "R" && f.length === 3) { downRate = Number(f[1]) || 0; upRate = Number(f[2]) || 0 }
        }
        links = c; journal = j; build();
    }
    function pad(s, n) { return (s + " ".repeat(n)).slice(0, n) }
    function clock(s) { return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0") }
    function rate(b) {
        if (b >= 1048576) return (b / 1048576).toFixed(1) + "M";
        if (b >= 1024) return (b / 1024).toFixed(0) + "K";
        return b.toFixed(0) + "B";
    }
    function row(s, hot, prompt) { return { s: s, c: hot ? "red" : "cy", a: hot ? 0.95 : (prompt ? 1.0 : 0.55) } }

    function build() {
        const out = [row("> trace --sockets --live", false, true)];
        for (let i = 0; i < 4; i++) {
            const c = links[i];
            out.push(c ? row("[ OK ] 0x" + c[1] + ":" + pad(c[2], 6) + pad(c[3], 6) + c[4])
                       : row(i === 0 ? "[ .. ] no active links" : ""));
        }
        out.push(row("> tail --follow /dev/journal", false, true));
        for (let i = 0; i < 4; i++) {
            const e = journal[i];
            if (!e) { out.push(row(i === 0 ? "[ .. ] journal silent" : "")); continue }
            const p = Number(e[2]);
            const mark = p <= 3 ? "[ICE ] " : (p === 4 ? "[WARN] " : "[ OK ] ");
            out.push(row(mark + e[1] + " " + pad(e[3], 19) + "0x" + e[4], p <= 4));
        }
        out.push(tracing
                 ? row("[WARN] trace program active: " + clock(traceSeconds), true)
                 : row("[ OK ] trace: clear   v " + rate(downRate) + "/s  ^ " + rate(upRate) + "/s"));
        out.push(row(reactor.alert ? "> !! countermeasures engaged: " + reactor.reason : "> ", reactor.alert, true));
        lines = out;
    }
}
