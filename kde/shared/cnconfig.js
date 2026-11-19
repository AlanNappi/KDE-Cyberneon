// CyberNeon runtime settings for the QML parts. install.sh overwrites the installed copy from cyberneon.conf;
// these are the defaults used when a package runs straight from the repository.
.pragma library
var REACTIVE = true;        // alert mode driven by real CPU / RAM / temperature
var ALERT_CPU = 85;         // percent
var ALERT_RAM = 85;         // percent
var ALERT_TEMP = 95;        // degrees C
var LIVE_TERMINAL = true;   // wallpaper terminal shows live (obfuscated) system data
var TERMINAL_PLATE = "";    // file:// URL of the empty terminal background (make_wallpaper.py --terminal-plate)
var TRACE_MBPS = 5;         // MB/s of network traffic that raises "trace program active"
var CYBER_OSD = false;      // Quickhack OSD replaces Plasma's native OSD
var SOUND_FX = false;       // CyberNeon sound effects
var LOW_POWER = 20;         // on battery below this percentage animations stop (0 = never)
var SENTINEL = true;        // the radar flags intrusion events (USB, wrong passwords, SSH, open ports, new devices)
var QUICKHACK = true;       // a click on a radar contact can close that program (after a confirmation)
