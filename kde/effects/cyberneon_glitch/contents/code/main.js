// CyberNeon Glitch - KWin scripted effect (Plasma 6, X11 and Wayland). Original.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
"use strict";

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
        var t = animationTime(60);
        // flicker: fade in, drop, come back
        animate({ window: window, duration: t, animations: [{ type: Effect.Opacity, from: 0.0, to: 1.0 }] });
        animate({ window: window, duration: t, delay: t + 10, animations: [{ type: Effect.Opacity, from: 1.0, to: 0.35 }] });
        animate({ window: window, duration: t, delay: 2 * t + 10, animations: [{ type: Effect.Opacity, from: 0.35, to: 1.0 }] });
        // lateral glitch jump that settles
        animate({ window: window, duration: 3 * t, curve: QEasingCurve.OutQuad,
                  animations: [{ type: Effect.Translation, from: { value1: -16, value2: 0 }, to: { value1: 0, value2: 0 } }] });
    },
    onClosed: function (window) {
        if (!glitch.eligible(window)) return;
        window.setData(Effect.WindowClosedGrabRole, true);
        var t = animationTime(50);
        animate({ window: window, duration: 3 * t, animations: [{ type: Effect.Opacity, from: 1.0, to: 0.0 }] });
        animate({ window: window, duration: 3 * t, curve: QEasingCurve.InQuad,
                  animations: [{ type: Effect.Translation, from: { value1: 0, value2: 0 }, to: { value1: 18, value2: 0 } }] });
    },
    init: function () {
        effects.windowAdded.connect(glitch.onAdded);
        effects.windowClosed.connect(glitch.onClosed);
    }
};
glitch.init();
