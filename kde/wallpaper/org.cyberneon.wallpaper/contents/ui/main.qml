// CyberNeon Live - animated wallpaper plugin for Plasma 6 (X11 and Wayland). Original artwork.
// The animation itself is CyberNeonLive.qml (shared with the SDDM login and the splash), a 1:1 port of the
// Budgie edition's live wallpaper.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root
    CyberNeonLive {
        anchors.fill: parent
        source: root.configuration.Image || ""
        animated: root.configuration.Animated !== false
    }
}
