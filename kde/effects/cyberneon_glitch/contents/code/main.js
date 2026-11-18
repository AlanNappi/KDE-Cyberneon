// CyberNeon Glitch v3 - KWin scripted effect with a GPU fragment shader (Plasma 6, X11 and Wayland). Original.
// Windows open and close with an RGB split, displaced slices, scanlines and cyan flashes that settle in ~0.4 s.
// While the HUD is in alert mode (bin/cn-kwin-alert, high system load) the glitch is stronger and lasts longer.
// Falls back to the plain flicker + lateral jump when shaders are not available.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
"use strict";

var shader = 0;
var shaderFile = "";
["glitch_core.frag", "glitch.frag"].some(function (file) {
    try { shader = effect.addFragmentShader(Effect.MapTexture | Effect.Modulate, file); shaderFile = file; } catch (e) { shader = 0; print("cyberneon_glitch: " + file + ": " + e); }
    return shader > 0;
});

print("cyberneon_glitch: shader id " + shader + " (" + shaderFile + ")");

var alertMode = false;
function readAlert() {
    var value = effect.readConfig("Alert", false);
    alertMode = value === true || value === "true";
    print("cyberneon_glitch: alert " + alertMode);
}
effect.configChanged.connect(readAlert);
readAlert();

var glitch = {
    eligible: function (window) {
        if (effects.hasActiveFullScreenEffect) return false;
        if (!window.normalWindow && !window.dialog) return false;
        if (window.popupWindow || window.skipsCloseAnimation) return false;
        return true;
    },
    onAdded: function (window) {
        if (!glitch.eligible(window)) return;
        window.setData(Effect.WindowAddedGrabRole, true);
        if (shader > 0) {
            var d = animationTime(alertMode ? 700 : 420);
            animate({ window: window, duration: d, curve: QEasingCurve.OutCubic,
                      animations: [{ type: Effect.ShaderUniform, fragmentShader: shader, uniform: "u_glitch", from: alertMode ? 1.8 : 1.0, to: 0.0 }] });
            animate({ window: window, duration: animationTime(110),
                      animations: [{ type: Effect.Opacity, from: 0.0, to: 1.0 }] });
            animate({ window: window, duration: d, curve: QEasingCurve.OutQuad,
                      animations: [{ type: Effect.Translation, from: { value1: -10, value2: 0 }, to: { value1: 0, value2: 0 } }] });
            return;
        }
        var t = animationTime(60);
        animate({ window: window, duration: t, animations: [{ type: Effect.Opacity, from: 0.0, to: 1.0 }] });
        animate({ window: window, duration: t, delay: t + 10, animations: [{ type: Effect.Opacity, from: 1.0, to: 0.35 }] });
        animate({ window: window, duration: t, delay: 2 * t + 10, animations: [{ type: Effect.Opacity, from: 0.35, to: 1.0 }] });
        animate({ window: window, duration: 3 * t, curve: QEasingCurve.OutQuad,
                  animations: [{ type: Effect.Translation, from: { value1: -16, value2: 0 }, to: { value1: 0, value2: 0 } }] });
    },
    onClosed: function (window) {
        if (!glitch.eligible(window)) return;
        window.setData(Effect.WindowClosedGrabRole, true);
        var d = animationTime(300);
        if (shader > 0) {
            animate({ window: window, duration: d, curve: QEasingCurve.InCubic,
                      animations: [{ type: Effect.ShaderUniform, fragmentShader: shader, uniform: "u_glitch", from: 0.0, to: alertMode ? 1.8 : 1.0 }] });
        }
        animate({ window: window, duration: d, curve: QEasingCurve.InQuad,
                  animations: [{ type: Effect.Opacity, from: 1.0, to: 0.0 }] });
        animate({ window: window, duration: d, curve: QEasingCurve.InQuad,
                  animations: [{ type: Effect.Translation, from: { value1: 0, value2: 0 }, to: { value1: 14, value2: 0 } }] });
    },
    init: function () {
        effects.windowAdded.connect(glitch.onAdded);
        effects.windowClosed.connect(glitch.onClosed);
    }
};
glitch.init();
