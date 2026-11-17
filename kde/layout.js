// CyberNeon - Plasma 6 desktop layout (run by install.sh through org.kde.PlasmaShell.evaluateScript).
// Placeholders @...@ are filled in by install.sh.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
//
// Same geometry as the Budgie version:
//   top bar: full width, 34 px, neon bottom line; red block 76-110 (org.cyberneon.redblock widget)
//   dock   : left edge below the bar, 90 px (navy 0-76, red bar 76-90 from the Plasma theme)
//   corner : the 45deg red fillet (90..110, 34..54) is painted in the wallpaper

var geo = screenGeometry(0);           // primary screen
var DOCK = 90, BAR = 34;

// ---------------------------------------------------------------- remove the current panels
panels().forEach(function (p) { p.remove(); });

// The top bar is created FIRST so it spans the whole width and the dock starts below it (as in Budgie):
// the bar's neon line crosses the dock's red bar, with the red block 76-110 above the line.
// ---------------------------------------------------------------- top bar (full width)
var bar = new Panel;
bar.location = "top";
bar.height = BAR;
bar.hiding = "none";
try { bar.floating = false; } catch (e) {}
bar.alignment = "left";
bar.offset = 0;

// red block 76-110 px (it positions itself in screen coordinates)
bar.addWidget("org.cyberneon.redblock");

// grid launcher like Budgie's AppMenu: Application Dashboard lives in kdeplasma-addons on Plasma 6,
// so fall back to Kicker / Kickoff when it is not installed
var launcherType = ["org.kde.plasma.kickerdash", "org.kde.plasma.kicker", "org.kde.plasma.kickoff"]
    .filter(function (t) { return knownWidgetTypes.indexOf(t) >= 0; })[0] || "org.kde.plasma.kickoff";
var dash = bar.addWidget(launcherType);
dash.currentConfigGroup = ["General"];
dash.writeConfig("icon", "@LOGO_ICON@");

bar.addWidget("org.kde.plasma.panelspacer");
bar.addWidget("org.kde.plasma.systemtray");

var clock = bar.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "yyyy-MM-dd");
clock.writeConfig("dateDisplayFormat", 1);               // date beside the time
clock.writeConfig("use24hFormat", 2);                    // always 24 h
clock.writeConfig("autoFontAndSize", false);
clock.writeConfig("fontFamily", "Chakra Petch");
clock.writeConfig("boldText", true);

bar.addWidget("org.kde.plasma.lock_logout");

// ---------------------------------------------------------------- left dock (below the bar)
var dock = new Panel;
dock.location = "left";
dock.height = DOCK;                    // thickness
dock.hiding = "none";
try { dock.floating = false; } catch (e) {}

var kickoff = dock.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "@MENU_ICON@");

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", "@LAUNCHERS@");

dock.addWidget("org.kde.plasma.panelspacer");
dock.addWidget("org.kde.plasma.pager");

// ---------------------------------------------------------------- wallpaper + desktop widgets
desktops().forEach(function (d) {
    d.wallpaperPlugin = "@WALLPAPER_PLUGIN@";             // org.cyberneon.wallpaper (animated) or org.kde.image
    d.currentConfigGroup = ["Wallpaper", "@WALLPAPER_PLUGIN@", "General"];
    d.writeConfig("Image", "@WALLPAPER@");
    d.writeConfig("FillMode", 2);                         // scaled and cropped (= Budgie "zoom")
});

// desktop widget coordinates are relative to the area left free by the panels (checked in the lab)
var desk = desktopForScreen(0);
if (desk) {
    desk.widgets().forEach(function (w) {
        if (w.type === "org.cyberneon.hud" || w.type === "org.cyberneon.clock") w.remove();
    });
    // HUD: bottom-right, 46 px from the right edge and 40 px from the bottom (as in Budgie)
    desk.addWidget("org.cyberneon.hud", geo.width - DOCK - 490 - 46, geo.height - BAR - 226 - 40, 490, 226);
    // clock: top-right, under the bar
    desk.addWidget("org.cyberneon.clock", geo.width - DOCK - 330 - 50, 40, 330, 140);
}

print("panels " + bar.id + " " + dock.id);
