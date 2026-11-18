// CyberNeon Radar - top-right HUD block for Plasma 6 (X11 and Wayland). Original artwork.
// A radar-style clock (sweep = seconds, red marker = hour, cyan marker = minute, the logo at the centre) and an
// objective tracker: the active window is the current objective, the other open windows are sub-objectives.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root
    readonly property color cy: "#5beedc"
    readonly property color red: "#ff2a4f"
    readonly property color navy: "#0b1620"
    property date now: new Date()
    property real secs: 0

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }
    FrameAnimation {    // smooth sweep
        running: true
        onTriggered: { const d = new Date(); root.secs = d.getSeconds() + d.getMilliseconds() / 1000 }
    }

    TaskManager.VirtualDesktopInfo { id: vdInfo }
    TaskManager.ActivityInfo { id: actInfo }
    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortLastActivated
        filterByVirtualDesktop: true
        filterByActivity: true
        virtualDesktop: vdInfo.currentDesktop
        activity: actInfo.currentActivity
    }

    fullRepresentation: Item {
        implicitWidth: 340
        implicitHeight: 470

        Item {
            id: hud
            anchors.fill: parent
            anchors.margins: 12
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: root.cy; shadowBlur: 0.6; blurMax: 16
                                        shadowOpacity: 0.6; shadowHorizontalOffset: 0; shadowVerticalOffset: 0; autoPaddingEnabled: true }

            // ------------------------------------------------ radar
            Item {
                id: radar
                anchors.right: parent.right
                width: 240; height: 240
                readonly property real r: width / 2

                Rectangle { anchors.fill: parent; radius: width / 2; color: Qt.rgba(0.043, 0.086, 0.125, 0.55)
                            border.color: Qt.rgba(0.36, 0.93, 0.86, 0.85); border.width: 1.5 }
                Rectangle { anchors.centerIn: parent; width: parent.width * 0.62; height: width; radius: width / 2
                            color: "transparent"; border.color: Qt.rgba(0.36, 0.93, 0.86, 0.25); border.width: 1 }
                Rectangle { anchors.centerIn: parent; width: parent.width * 0.3; height: width; radius: width / 2
                            color: "transparent"; border.color: Qt.rgba(0.36, 0.93, 0.86, 0.2); border.width: 1 }
                Repeater {   // 60 ticks
                    model: 60
                    Rectangle {
                        required property int index
                        x: radar.r - width / 2; y: 3
                        width: index % 5 === 0 ? 2 : 1; height: index % 5 === 0 ? 10 : 5
                        color: index % 15 === 0 ? root.red : Qt.rgba(0.36, 0.93, 0.86, 0.7)
                        transform: Rotation { origin.x: width / 2; origin.y: radar.r - 3; angle: index * 6 }
                    }
                }
                Repeater {   // hour labels at the quarter ticks
                    model: ["00", "15", "30", "45"]
                    Text {
                        required property int index
                        required property string modelData
                        readonly property real a: index * Math.PI / 2
                        x: radar.r + Math.sin(a) * (radar.r - 24) - width / 2
                        y: radar.r - Math.cos(a) * (radar.r - 24) - height / 2
                        text: modelData; color: Qt.rgba(0.36, 0.93, 0.86, 0.7)
                        font.family: "Rajdhani"; font.bold: true; font.pixelSize: 11
                    }
                }
                Shape {   // sweep wedge
                    anchors.fill: parent
                    rotation: root.secs * 6
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeWidth: -1
                        fillGradient: ConicalGradient {
                            centerX: radar.r; centerY: radar.r; angle: 90
                            GradientStop { position: 0.0; color: Qt.rgba(0.36, 0.93, 0.86, 0.45) }
                            GradientStop { position: 0.12; color: Qt.rgba(0.36, 0.93, 0.86, 0.0) }
                            GradientStop { position: 1.0; color: Qt.rgba(0.36, 0.93, 0.86, 0.0) }
                        }
                        startX: radar.r; startY: radar.r
                        PathAngleArc { centerX: radar.r; centerY: radar.r; radiusX: radar.r - 2; radiusY: radar.r - 2; startAngle: -90; sweepAngle: -44 }
                        PathLine { x: radar.r; y: radar.r }
                    }
                    ShapePath {
                        strokeColor: root.cy; strokeWidth: 1.5
                        startX: radar.r; startY: radar.r
                        PathLine { x: radar.r; y: 2 }
                    }
                }
                Repeater {   // markers: hour (red diamond), minute (cyan square)
                    model: 2
                    Item {
                        required property int index
                        readonly property real a: index === 0
                            ? ((root.now.getHours() % 12) + root.now.getMinutes() / 60) * Math.PI / 6
                            : (root.now.getMinutes() + root.now.getSeconds() / 60) * Math.PI / 30
                        readonly property real d: index === 0 ? radar.r * 0.42 : radar.r * 0.7
                        x: radar.r + Math.sin(a) * d - 7; y: radar.r - Math.cos(a) * d - 7
                        width: 14; height: 14
                        Rectangle {
                            anchors.centerIn: parent; width: 10; height: 10
                            rotation: parent.index === 0 ? 45 : 0
                            color: parent.index === 0 ? root.red : "transparent"
                            border.color: parent.index === 0 ? root.red : root.cy; border.width: 2
                        }
                    }
                }
                Kirigami.Icon {
                    anchors.centerIn: parent; width: 34; height: 34
                    source: "cyberneon-launcher"; fallback: "cyberneon-logo"
                }
            }
            Text {
                anchors.right: radar.right; anchors.top: radar.bottom; anchors.topMargin: 6
                text: Qt.formatTime(root.now, "HH:mm") + "  //  " + Qt.formatDate(root.now, "ddd dd.MM").toUpperCase()
                color: root.cy
                font.family: "Rajdhani"; font.bold: true; font.pixelSize: 16; font.letterSpacing: 2
            }

            // ------------------------------------------------ objective tracker
            Column {
                id: tracker
                anchors.right: parent.right
                anchors.top: radar.bottom; anchors.topMargin: 40
                width: hud.width
                spacing: 6

                Row {
                    anchors.right: parent.right; spacing: 8
                    Text { text: "OBJECTIVE"; color: root.red; font.family: "Rajdhani"; font.bold: true; font.pixelSize: 14; font.letterSpacing: 3 }
                    Rectangle { width: 10; height: 10; rotation: 45; color: root.red; anchors.verticalCenter: parent.verticalCenter }
                }
                Repeater {
                    model: tasks
                    delegate: Row {
                        required property int index
                        required property var model
                        visible: index < 5
                        height: visible ? implicitHeight : 0
                        anchors.right: parent.right
                        layoutDirection: Qt.RightToLeft
                        spacing: 8
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: index === 0 ? 10 : 8; height: width
                            color: index === 0 ? root.cy : "transparent"
                            border.color: index === 0 ? root.cy : Qt.rgba(0.36, 0.93, 0.86, 0.6); border.width: 1.5
                        }
                        Text {
                            width: Math.min(implicitWidth, tracker.width - 24)
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignRight
                            text: (parent.model.display || "").toString()
                            color: index === 0 ? root.cy : Qt.rgba(0.49, 0.87, 0.84, 0.75)
                            font.family: "Rajdhani"; font.bold: index === 0; font.pixelSize: index === 0 ? 17 : 14
                            font.capitalization: Font.AllUppercase; font.letterSpacing: 1
                        }
                    }
                }
                Text {
                    anchors.right: parent.right
                    visible: tasks.count === 0
                    text: "NO ACTIVE GIG // STANDBY"
                    color: Qt.rgba(0.49, 0.87, 0.84, 0.7)
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 15; font.letterSpacing: 2
                }
                Text {
                    anchors.right: parent.right
                    text: "WORKSPACE " + (Math.max(0, (vdInfo.desktopIds || []).indexOf(vdInfo.currentDesktop)) + 1) + " / " + vdInfo.numberOfDesktops
                    color: Qt.rgba(1, 0.165, 0.31, 0.85)
                    font.family: "Rajdhani"; font.bold: true; font.pixelSize: 12; font.letterSpacing: 3
                }
            }
        }
    }
}
