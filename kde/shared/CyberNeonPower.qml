// CyberNeon power state: battery level and "low power" (on battery below LOW_POWER percent).
// Works on any laptop through Plasma's power management data; on a desktop hasBattery stays false.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "cnconfig.js" as Cfg

Item {
    visible: false
    readonly property var battery: source.data["Battery"] || ({})
    readonly property bool hasBattery: battery["Has Battery"] === true
    readonly property int percent: Number(battery["Percent"]) || 0
    readonly property string batteryState: battery["State"] || ""
    readonly property bool charging: batteryState === "Charging"
    readonly property bool discharging: hasBattery && batteryState === "Discharging"
    readonly property bool lowPower: Cfg.LOW_POWER > 0 && discharging && percent < Cfg.LOW_POWER

    P5Support.DataSource { id: source; engine: "powermanagement"; connectedSources: ["Battery"] }
}
