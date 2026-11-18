// CyberNeon v3 - Plasma 6 desktop layout (run by install.sh through org.kde.PlasmaShell.evaluateScript).
// Placeholders @...@ are filled in by install.sh.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
//
// A game-HUD style desktop in four zones (original artwork, real system data):
//   top-left    : floating badge panel (logo launcher, workspaces) + Biomonitor widget
//   top-right   : floating panel (system tray, clock, lock/logout) + Radar clock / objective tracker widget
//   bottom      : floating dock, centred, sized to its icons (quick slots)
//   bottom-right: Chrono counter widget          (notifications pop up bottom-left: plasmanotifyrc)
// Panels are glass with blur behind and a neon glow (Plasma theme shadows).

var geo = screenGeometry(0);           // primary screen
var BAR = 44, DOCK = 62, GAP = 8;

// ---------------------------------------------------------------- remove the current panels
panels().forEach(function (p) { p.remove(); });

function floatingPanel(location, height, alignment) {
    var p = new Panel;
    p.location = location;
    p.height = height;
    p.hiding = "none";
    try { p.floating = true; } catch (e) {}
    try { p.lengthMode = "fit"; } catch (e) {}
    p.alignment = alignment;
    return p;
}

// ---------------------------------------------------------------- top-left: badge panel
var badge = floatingPanel("top", BAR, "left");
var launcherType = ["org.kde.plasma.kickerdash", "org.kde.plasma.kicker", "org.kde.plasma.kickoff"]
    .filter(function (t) { return knownWidgetTypes.indexOf(t) >= 0; })[0] || "org.kde.plasma.kickoff";
var dash = badge.addWidget(launcherType);
dash.currentConfigGroup = ["General"];
dash.writeConfig("icon", "@LOGO_ICON@");
var pager = badge.addWidget("org.kde.plasma.pager");
pager.currentConfigGroup = ["General"];
pager.writeConfig("displayedText", "Number");

// ---------------------------------------------------------------- top-right: system panel
var sys = floatingPanel("top", BAR, "right");
sys.addWidget("org.kde.plasma.systemtray");
var clock = sys.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", false);
clock.writeConfig("use24hFormat", 2);                    // always 24 h
clock.writeConfig("autoFontAndSize", false);
clock.writeConfig("fontFamily", "Orbitron");
clock.writeConfig("boldText", false);
sys.addWidget("org.kde.plasma.lock_logout");

// ---------------------------------------------------------------- bottom: dock (quick slots)
var dock = floatingPanel("bottom", DOCK, "center");
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", "@LAUNCHERS@");
tasks.writeConfig("iconSpacing", 2);

// ---------------------------------------------------------------- wallpaper + HUD widgets
desktops().forEach(function (d) {
    d.wallpaperPlugin = "@WALLPAPER_PLUGIN@";             // org.cyberneon.wallpaper (animated) or org.kde.image
    d.currentConfigGroup = ["Wallpaper", "@WALLPAPER_PLUGIN@", "General"];
    d.writeConfig("Image", "@WALLPAPER@");
    d.writeConfig("FillMode", 2);                         // scaled and cropped
});

// desktop widget coordinates are relative to the area left free by the panels
var desk = desktopForScreen(0);
if (desk) {
    desk.widgets().forEach(function (w) {
        if (w.type.indexOf("org.cyberneon.") === 0) w.remove();
    });
    var freeH = geo.height - (BAR + 2 * GAP) - (DOCK + 2 * GAP);
    desk.addWidget("org.cyberneon.biomonitor", 12, 2, 560, 104);
    desk.addWidget("org.cyberneon.radar", geo.width - 340 - 16, 4, 340, 470);
    desk.addWidget("org.cyberneon.chrono", geo.width - 420 - 20, freeH - 160 - 8, 420, 160);
}

print("panels " + badge.id + " " + sys.id + " " + dock.id);
