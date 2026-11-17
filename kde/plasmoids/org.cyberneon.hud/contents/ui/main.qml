// CyberNeon HUD - Plasma 6 desktop widget (works on X11 and Wayland).
// Same drawing as the conky HUD of the Budgie version.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    // replaced by install.sh (HUD_LABEL in cyberneon.conf, default: user name in capitals)
    readonly property string label: "@HUD_LABEL@"

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Sensors.Sensor { id: cpu;  sensorId: "cpu/all/usage";               updateRateLimit: 2000 }
    Sensors.Sensor { id: mem;  sensorId: "memory/physical/usedPercent"; updateRateLimit: 2000 }
    Sensors.Sensor { id: disk; sensorId: "disk/all/usedPercent";        updateRateLimit: 10000 }

    fullRepresentation: Item {
        implicitWidth: 490
        implicitHeight: 226

        Canvas {
            id: hud
            anchors.fill: parent

            readonly property color cy: "#5beedc"
            readonly property color dim: "#1f4a4f"
            readonly property color navy: "#111e29"
            readonly property color red: "#ff2a4f"

            function poly(ctx, pts) {
                ctx.beginPath(); ctx.moveTo(pts[0], pts[1])
                for (var i = 2; i < pts.length; i += 2) ctx.lineTo(pts[i], pts[i + 1])
                ctx.closePath()
            }

            function stat(ctx, y, label, value, w) {
                var pct = Math.max(0, Math.min(100, Number(value) || 0))
                ctx.fillStyle = dim; ctx.fillRect(0, y, w, 6)
                ctx.fillStyle = cy;  ctx.fillRect(0, y, Math.max(4, w * pct / 100), 6)
                ctx.font = 'bold 15px "Chakra Petch"'
                ctx.textAlign = "left";  ctx.fillText(label, 3, y + 25)
                ctx.textAlign = "right"; ctx.fillText(pct.toFixed(1) + "%", w, y + 25)
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var W = 330

                stat(ctx, 4,  "Total CPU Usage",      cpu.value,  W)
                stat(ctx, 48, "Used Physical Memory", mem.value,  W)
                stat(ctx, 92, "Root Filesystem",      disk.value, W)

                // hatched block with a chamfered bottom-left corner
                var top = 134, bot = 214
                ctx.save()
                poly(ctx, [0, top, W, top, W, bot, 42, bot, 0, bot - 42]); ctx.clip()
                ctx.fillStyle = Qt.rgba(cy.r, cy.g, cy.b, 0.92)
                for (var x = -120; x < W + 40; x += 26) {
                    poly(ctx, [x, bot, x + 13, bot, x + 13 + (bot - top), top, x + (bot - top), top]); ctx.fill()
                }
                ctx.restore()

                // vertical name plate
                ctx.fillStyle = cy
                ctx.fillRect(350, 4, 12, bot - 4)
                poly(ctx, [370, 4, 434, 4, 478, 48, 478, bot, 370, bot]); ctx.fill()
                ctx.save()
                ctx.translate(412, (bot + 4) / 2)
                ctx.rotate(Math.PI / 2)
                ctx.fillStyle = navy
                ctx.font = "40px Orbitron"
                ctx.textAlign = "center"; ctx.textBaseline = "middle"
                ctx.fillText(root.label, 0, 0)
                ctx.restore()

                // red status pixel
                ctx.fillStyle = red
                ctx.fillRect(455, bot - 22, 12, 12)
            }

            Timer {
                interval: 2000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: hud.requestPaint()
            }
        }
    }
}
