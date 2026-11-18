// CyberNeon Live - animated wallpaper plugin for Plasma 6 (X11 and Wayland). Original artwork.
// The animation itself is CyberNeonLive.qml (shared with the SDDM login and the splash), a 1:1 port of the
// Budgie edition's live wallpaper. On the desktop it also reacts to the real system (LiveData.qml), which is loaded
// separately so that the wallpaper keeps working if a Plasma data module is missing.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import org.kde.plasma.plasmoid
import "cnconfig.js" as Cfg

WallpaperItem {
    id: root

    Loader {
        id: live
        active: Qt.application.name === "plasmashell"        // never on the lock screen
        source: "LiveData.qml"
    }

    CyberNeonLive {
        anchors.fill: parent
        source: root.configuration.Image || ""
        animated: root.configuration.Animated !== false
        running: !(live.item && live.item.lowPower)
        alert: live.item ? live.item.alert : false
        terminalLines: live.item ? live.item.lines : []
        terminalPlate: Cfg.TERMINAL_PLATE
    }
}
