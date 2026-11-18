// CyberNeon Quickhack OSD: volume, brightness and every other Plasma on-screen message as an "upload" bar above the dock.
// Plasma stops emitting its OSD signals when the native OSD is off, so the requests are read from the session bus
// (bin/cn-bus-watch). Two overlapping long polls make sure no event is lost between one poll and the next.
// The same watcher reports new notifications for the optional "incoming call" sound.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import QtQuick.Window
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import "cnconfig.js" as Cfg

Item {
    id: osd
    visible: false

    readonly property color cy: "#5beedc"
    readonly property color red: "#ff2a4f"
    readonly property color navy: "#0b1620"
    readonly property int dockSpace: 62 + 2 * 8 + 10           // layout.js: dock height + its gaps + margin
    readonly property bool watching: Cfg.CYBER_OSD || Cfg.SOUND_FX

    signal notified()

    property string title: ""
    property string message: ""
    property real value: -1                                     // 0..1, -1 = text only
    property int percent: 0
    property real lastTs: 0
    property int seq: 0

    P5Support.DataSource {
        id: watcher
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            osd.handle(data.stdout || "");
            osd.poll(source.indexOf("cn-bus-watch\" 0 ") >= 0 ? 0 : 400);
        }
    }
    function poll(holdMs) {
        watcher.connectSource('"$HOME/.local/share/cyberneon/bin/cn-bus-watch" ' + holdMs + ' #' + (++seq));
    }
    Component.onCompleted: if (watching) { poll(0); poll(400) }

    function handle(out) {
        for (const row of out.split("\n")) {
            if (!row) continue;
            let e;
            try { e = JSON.parse(row) } catch (err) { continue }
            if (e.ts <= lastTs) continue;
            lastTs = e.ts;
            if (e.m === "Notify") notified();
            else if (Cfg.CYBER_OSD) show(e.m, e.a);
        }
    }

    function bar(label, p, max, audio) {
        title = label; percent = p; message = audio && p === 0 ? "MUTED // OFFLINE" : "";
        value = Math.max(0, Math.min(1, p / (max || 100)));
        pop();
    }
    function text(label, s) { title = label; message = String(s).toUpperCase(); value = -1; pop() }
    function onOff(b) { return b ? "ONLINE" : "OFFLINE" }

    function show(m, a) {
        switch (m) {
        case "volumeChanged":                  return bar("AUDIO OUTPUT", a[0], a[1], true);
        case "microphoneVolumeChanged":        return bar("MIC INPUT", a[0], 100, true);
        case "mediaPlayerVolumeChanged":       return bar(String(a[1] || "MEDIA").toUpperCase(), a[0], 100, true);
        case "brightnessChanged":
        case "screenBrightnessChanged":        return bar("OPTICS // BRIGHTNESS", a[0]);
        case "keyboardBrightnessChanged":      return bar("KEY BACKLIGHT", a[0]);
        case "kbdLayoutChanged":               return text("INPUT LAYOUT", a[0]);
        case "virtualDesktopChanged":          return text("SECTOR", a[0]);
        case "touchpadEnabledChanged":         return text("TOUCHPAD", onOff(a[0]));
        case "wifiEnabledChanged":             return text("WI-FI LINK", onOff(a[0]));
        case "bluetoothEnabledChanged":        return text("BLUETOOTH", onOff(a[0]));
        case "wwanEnabledChanged":             return text("MOBILE LINK", onOff(a[0]));
        case "virtualKeyboardEnabledChanged":  return text("VIRTUAL KEYBOARD", onOff(a[0]));
        case "powerManagementInhibitedChanged":return text("SLEEP LOCK", onOff(a[0]));
        case "powerProfileChanged":            return text("POWER PROFILE", a[0]);
        case "showText":                       return text("SYSTEM", a[1]);
        case "hide":                           win.visible = false; return;
        }
    }
    function pop() { win.visible = true; hideTimer.restart() }
    Timer { id: hideTimer; interval: 1800; onTriggered: win.visible = false }

    // the dialog is placed by Plasma relative to this point of the desktop, every time it is shown
    Item {
        id: anchorPoint
        parent: osd.Window.contentItem
        x: parent ? parent.width / 2 : 0
        y: parent ? parent.height - osd.dockSpace : 0
        width: 1; height: 1
    }

    PlasmaCore.Dialog {
        id: win
        visualParent: anchorPoint
        type: PlasmaCore.Dialog.OnScreenDisplay
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
        location: PlasmaCore.Types.BottomEdge
        backgroundHints: PlasmaCore.Dialog.NoBackground
        outputOnly: true
        hideOnWindowDeactivate: false

        mainItem: Item {
            id: panel
            width: 500; height: 76

            Item {
                id: plate
                anchors.fill: parent; anchors.margins: 10
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: osd.cy; shadowBlur: 0.7; blurMax: 16; shadowOpacity: 0.7
                                            shadowHorizontalOffset: 0; shadowVerticalOffset: 0; autoPaddingEnabled: false }
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: Qt.rgba(0.043, 0.086, 0.125, 0.94); strokeColor: osd.cy; strokeWidth: 1.5; joinStyle: ShapePath.MiterJoin
                        startX: 12; startY: 0.75
                        PathLine { x: plate.width - 0.75; y: 0.75 } PathLine { x: plate.width - 0.75; y: plate.height - 12 }
                        PathLine { x: plate.width - 12; y: plate.height - 0.75 } PathLine { x: 0.75; y: plate.height - 0.75 }
                        PathLine { x: 0.75; y: 12 } PathLine { x: 12; y: 0.75 }
                    }
                    ShapePath {
                        fillColor: osd.red; strokeWidth: -1
                        startX: 12; startY: 0
                        PathLine { x: 158; y: 0 } PathLine { x: 144; y: 16 } PathLine { x: 0; y: 16 } PathLine { x: 0; y: 12 } PathLine { x: 12; y: 0 }
                    }
                }
                Text {
                    x: 16; y: 0; height: 16; verticalAlignment: Text.AlignVCenter
                    text: "QUICKHACK // UPLOAD"
                    color: osd.navy
                    font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 10; font.letterSpacing: 1
                }
                Text {
                    x: 166; y: 1
                    width: plate.width - x - 62; elide: Text.ElideRight
                    text: osd.title
                    color: osd.cy
                    font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 13; font.letterSpacing: 2
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 12; y: 1
                    visible: osd.value >= 0
                    text: osd.percent + "%"
                    color: osd.percent === 0 ? osd.red : osd.cy
                    font.family: "Orbitron"; font.bold: true; font.pixelSize: 14
                }
                Row {
                    x: 12; y: 26; spacing: 2
                    visible: osd.value >= 0 && osd.message === ""
                    Repeater {
                        model: 46
                        Rectangle {
                            required property int index
                            readonly property bool lit: index < Math.round(osd.value * 46)
                            width: 7; height: 16
                            color: lit ? (index >= 40 ? osd.red : osd.cy) : Qt.rgba(0.36, 0.93, 0.86, 0.12)
                        }
                    }
                }
                Text {
                    x: 12; y: 24; width: plate.width - 24; elide: Text.ElideRight
                    visible: osd.message !== ""
                    text: osd.message
                    color: osd.value === 0 ? osd.red : osd.cy
                    font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 16; font.letterSpacing: 2
                }
            }
        }
    }
}
