// CyberNeon reactor: turns real system load into the HUD alert state ("cyberpsychosis mode").
// Alert starts after ALERT_ENTER seconds over a limit and ends after ALERT_EXIT seconds clearly below it, so short
// spikes do not make the desktop flash. RAM excludes the page cache (cached memory is not pressure).
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import org.kde.ksysguard.sensors as Sensors
import "cnconfig.js" as Cfg

Item {
    id: r
    visible: false

    readonly property int alertEnter: 3
    readonly property int alertExit: 6

    readonly property real cpu: Number(cpuSensor.value) || 0
    readonly property real ram: Number(ramSensor.value) || 0
    readonly property real temp: Math.max(Number(cpuTemp.value) || 0, Number(gpuTemp.value) || 0)

    property bool alert: false
    property string reason: ""
    property int hotFor: 0
    property int calmFor: 0

    Sensors.Sensor { id: cpuSensor; sensorId: "cpu/all/usage";              updateRateLimit: 1000 }
    Sensors.Sensor { id: ramSensor; sensorId: "memory/physical/usedPercent"; updateRateLimit: 1000 }
    Sensors.Sensor { id: cpuTemp;   sensorId: "cpu/all/maximumTemperature"; updateRateLimit: 2000 }
    Sensors.Sensor { id: gpuTemp;   sensorId: "gpu/gpu0/temperature";       updateRateLimit: 2000 }

    function tick() {
        const hot = [];
        if (cpu >= Cfg.ALERT_CPU) hot.push("CPU " + cpu.toFixed(0) + "%");
        if (ram >= Cfg.ALERT_RAM) hot.push("RAM " + ram.toFixed(0) + "%");
        if (temp >= Cfg.ALERT_TEMP) hot.push("TEMP " + temp.toFixed(0) + "C");
        const calm = cpu < Cfg.ALERT_CPU - 10 && ram < Cfg.ALERT_RAM - 5 && temp < Cfg.ALERT_TEMP - 5;
        if (hot.length) reason = hot.join("  ");
        hotFor = hot.length ? hotFor + 1 : 0;
        calmFor = calm ? calmFor + 1 : 0;
        if (!alert && hotFor >= alertEnter) alert = true;
        else if (alert && calmFor >= alertExit) alert = false;
    }

    Timer { interval: 1000; repeat: true; running: Cfg.REACTIVE; onTriggered: r.tick() }
}
