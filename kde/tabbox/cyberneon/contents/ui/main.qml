// CyberNeon window switcher (Alt+Tab) for KWin 6: a row of HUD cards with live window thumbnails; the selected
// window gets a red "target lock" (thick neon frame, corner brackets, tag). Original artwork.
// FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
import QtQuick
import QtQuick.Shapes
import org.kde.plasma.core as PlasmaCore
import org.kde.kwin as KWin
import org.kde.kirigami as Kirigami

KWin.TabBoxSwitcher {
    id: tabBox

    Instantiator {
        active: tabBox.visible
        delegate: PlasmaCore.Dialog {
            location: PlasmaCore.Types.Floating
            visible: true
            flags: Qt.ToolTip | Qt.X11BypassWindowManagerHint
            x: tabBox.screenGeometry.x + tabBox.screenGeometry.width * 0.5 - mainItem.width * 0.5
            y: tabBox.screenGeometry.y + tabBox.screenGeometry.height * 0.5 - mainItem.height * 0.5

            mainItem: FocusScope {
                id: main
                focus: true
                readonly property int cardW: 280
                readonly property int cardH: 214
                width: Math.min(tabBox.screenGeometry.width * 0.9, Math.max(cardW + 20, list.count * (cardW + 16) + 4))
                height: cardH + 46

                Text {
                    x: 6; y: 0
                    text: "// SWITCH TARGET"
                    color: "#5beedc"
                    font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 14; font.letterSpacing: 3
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 6; y: 0
                    text: (list.currentIndex + 1).toString().padStart(2, "0") + " / " + list.count.toString().padStart(2, "0")
                    color: "#ff2a4f"
                    font.family: "Orbitron"; font.pixelSize: 14
                }

                ListView {
                    id: list
                    y: 28; width: parent.width; height: main.cardH + 12
                    orientation: ListView.Horizontal
                    spacing: 16
                    clip: true
                    model: tabBox.model
                    currentIndex: tabBox.currentIndex
                    highlightMoveDuration: 120
                    onCurrentIndexChanged: tabBox.currentIndex = currentIndex
                    delegate: Item {
                        id: card
                        required property int index
                        required property var model
                        readonly property bool sel: ListView.isCurrentItem
                        width: main.cardW; height: main.cardH

                        TapHandler { onTapped: tabBox.model.activate(card.index) }

                        Shape {   // cut-corner card frame
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                fillColor: card.sel ? Qt.rgba(1, 0.165, 0.31, 0.10) : Qt.rgba(0.043, 0.086, 0.125, 0.55)
                                strokeColor: card.sel ? "#ff2a4f" : Qt.rgba(0.36, 0.93, 0.86, 0.55)
                                strokeWidth: card.sel ? 2.5 : 1.2
                                joinStyle: ShapePath.MiterJoin
                                startX: 14; startY: 1
                                PathLine { x: card.width - 1; y: 1 }
                                PathLine { x: card.width - 1; y: card.height - 14 }
                                PathLine { x: card.width - 14; y: card.height - 1 }
                                PathLine { x: 1; y: card.height - 1 }
                                PathLine { x: 1; y: 14 }
                                PathLine { x: 14; y: 1 }
                            }
                        }
                        Item {   // live thumbnail
                            x: 10; y: 10; width: parent.width - 20; height: parent.height - 50
                            KWin.WindowThumbnail {
                                anchors.fill: parent
                                wId: card.model.windowId
                            }
                            Repeater {   // scanlines over the thumbnail of the selected card
                                model: card.sel ? Math.floor(parent.height / 4) : 0
                                Rectangle { y: index * 4; width: parent.width; height: 1; color: Qt.rgba(1, 0.165, 0.31, 0.08) }
                            }
                        }
                        Row {
                            x: 10; y: parent.height - 34; width: parent.width - 20; spacing: 8
                            Kirigami.Icon { width: 22; height: 22; source: card.model.icon }
                            Text {
                                width: parent.width - 30; anchors.verticalCenter: parent.verticalCenter
                                text: card.model.caption
                                elide: Text.ElideRight
                                color: card.sel ? "#ff2a4f" : "#7eddd5"
                                font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 12
                                font.capitalization: Font.AllUppercase; font.letterSpacing: 1
                            }
                        }
                        // target lock: corner brackets + tag
                        Repeater {
                            model: card.sel ? 4 : 0
                            Item {
                                required property int index
                                readonly property bool r: index % 2 === 1
                                readonly property bool b: index > 1
                                x: r ? card.width + 4 - 18 : -4; y: b ? card.height + 4 - 18 : -4
                                width: 18; height: 18
                                Rectangle { width: 18; height: 3; color: "#ff2a4f"; y: parent.b ? 15 : 0 }
                                Rectangle { width: 3; height: 18; color: "#ff2a4f"; x: parent.r ? 15 : 0 }
                            }
                        }
                        Rectangle {
                            visible: card.sel
                            anchors.right: parent.right; anchors.rightMargin: 12; y: 12
                            width: tag.implicitWidth + 12; height: 18; color: "#ff2a4f"
                            Text { id: tag; anchors.centerIn: parent; text: "TARGET"; color: "#0b1620"
                                   font.family: "Chakra Petch"; font.bold: true; font.pixelSize: 11; font.letterSpacing: 2 }
                        }
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Left) list.decrementCurrentIndex();
                    else if (event.key === Qt.Key_Right) list.incrementCurrentIndex();
                    else return;
                    tabBox.currentIndex = list.currentIndex;
                }
            }

            onSceneGraphError: () => {}
        }
    }
}
