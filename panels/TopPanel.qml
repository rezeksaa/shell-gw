import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects 

import "."
import "../components/"
import "../widgets/"
import "../settings/"
import "../popups/"
import "../panels/"
import "../shell/"

PanelWindow {
    id: musicWindow
    
    anchors { top: true; left: true; right: true }
    margins { top: shellRoot.showWidgets ? 35 : -620 }

    Behavior on margins.top {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutQuint
        }
    }

    aboveWindows: true
    
    implicitHeight: container.implicitHeight + 100 
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    Item {
        id: wrapper
        width: 650 + 40 
        implicitHeight: container.implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        
        opacity: shellRoot.showWidgets ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        BarCorner {
            width: 20; implicitHeight: 20; anchors.top: parent.top; anchors.right: container.left
            position: "top-right"; cornerRadius: 20; shapeColor: shellRoot.backgroundColor
        }

        BarCorner {
            width: 20; implicitHeight: 20; anchors.top: parent.top; anchors.left: container.right
            position: "top-left"; cornerRadius: 20; shapeColor: shellRoot.backgroundColor
        }

        Rectangle {
            id: container
            width: 650
            implicitHeight: Math.max(musicContent.implicitHeight, calendarContent.implicitHeight) + 40
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            color: shellRoot.backgroundColor
            
            
            radius: shellRoot.globalRadius 

            
            
            Rectangle {
                id: topSquarePatch
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: shellRoot.globalRadius 
                color: shellRoot.backgroundColor
                z: 0 
            }

            RowLayout {
                id: mainLayout
                anchors.fill: parent
                anchors.margins: 40
                anchors.topMargin: 10
                spacing: 0
                z: 1 

                ColumnLayout {
                    id: musicContent
                    Layout.preferredWidth: 300
                    Layout.fillHeight: true
                    spacing: 0

                    readonly property var spotifyPlayer: {
                        const players = Mpris.players.values;
                        return players.find(p => p.identity.toLowerCase().includes("spotify")) || null;
                    }

                    
                    ColumnLayout {
                        id: placeholder
                        visible: !musicContent.spotifyPlayer
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter 
                        spacing: 10
                        Text { text: "󰎆"; color: shellRoot.inactiveColor; font.pixelSize: 64; opacity: 0.2; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "no media"; color: shellRoot.inactiveColor; font.pixelSize: 12; font.bold: true; opacity: 0.4; Layout.alignment: Qt.AlignHCenter }
                    }

                    
                    ColumnLayout {
                        id: activeSpotifyUI
                        visible: !!musicContent.spotifyPlayer
                        property var player: musicContent.spotifyPlayer
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter 
                        Layout.fillWidth: true 
                        spacing: 20

                        property real trackPosition: player ? player.position : 0
                        Timer {
                            interval: 500; repeat: true
                            running: activeSpotifyUI.visible && activeSpotifyUI.player && activeSpotifyUI.player.playbackState === MprisPlaybackState.Playing
                            onTriggered: activeSpotifyUI.trackPosition = activeSpotifyUI.player.position
                        }

                        Item {
                            id: artContainer
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 140; Layout.preferredHeight: 140
                            Image {
                                id: albumArt; anchors.fill: parent
                                source: (activeSpotifyUI.player && activeSpotifyUI.player.metadata["mpris:artUrl"]) || ""
                                fillMode: Image.PreserveAspectCrop; mipmap: true
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle { width: 140; height: 140; radius: 12 }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter; spacing: 4
                            Text {
                                text: (activeSpotifyUI.player && activeSpotifyUI.player.trackTitle) || "Not Playing"
                                color: shellRoot.activeColor; font.family: "JetBrainsMono Nerd Font"; font.bold: true; font.pixelSize: 14; Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                            }
                            Text {
                                text: (activeSpotifyUI.player && activeSpotifyUI.player.trackArtist) || "Unknown"
                                color: shellRoot.inactiveColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                            }
                        }

                        
                        Rectangle {
                            id: progressBg
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 220; Layout.preferredHeight: 4; color: shellRoot.gray; radius: 2
                            
                            Rectangle {
                                id: progressBar
                                anchors.left: parent.left
                                height: parent.height
                                width: (activeSpotifyUI.player && activeSpotifyUI.player.length > 0) 
                                       ? parent.width * (activeSpotifyUI.trackPosition / activeSpotifyUI.player.length) 
                                       : 0
                                color: shellRoot.accentColor; radius: 2
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.Linear } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                cursorShape: Qt.PointingHandCursor 
                                onClicked: (mouse) => {
                                    if (activeSpotifyUI.player && activeSpotifyUI.player.length > 0) {
                                        let ratio = mouse.x / width;
                                        activeSpotifyUI.player.position = ratio * activeSpotifyUI.player.length;
                                        activeSpotifyUI.trackPosition = activeSpotifyUI.player.position;
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter; spacing: 25
                            Text { 
                                text: "󰒮"; color: shellRoot.activeColor; font.pixelSize: 18
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: activeSpotifyUI.player.previous() } 
                            }
                            Rectangle {
                                width: 38; height: 38; radius: 19; color: shellRoot.activeColor
                                Text {
                                    anchors.centerIn: parent; text: (activeSpotifyUI.player && activeSpotifyUI.player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                                    color: shellRoot.backgroundColor; font.pixelSize: 18
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: activeSpotifyUI.player.togglePlaying() }
                            }
                            Text { 
                                text: "󰒭"; color: shellRoot.activeColor; font.pixelSize: 18
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: activeSpotifyUI.player.next() } 
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillHeight: true; Layout.leftMargin: 40; Layout.rightMargin: 40
                    width: 1; color: shellRoot.textColor; opacity: 0.1
                }

                
                ColumnLayout {
                    id: calendarContent
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.topMargin: 20; spacing: 15
                    readonly property var now: new Date()
                    Text {
                        text: calendarContent.now.toLocaleString(Qt.locale(), "MMMM yyyy").toLowerCase()
                        color: shellRoot.activeColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; font.bold: true
                    }

                    GridLayout {
                        columns: 7; columnSpacing: 10; rowSpacing: 8; Layout.fillWidth: true
                        Repeater {
                            model: ["su", "mo", "tu", "we", "th", "fr", "sa"]
                            delegate: Text {
                                text: modelData; color: shellRoot.inactiveColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; Layout.alignment: Qt.AlignHCenter
                            }
                        }
                        Repeater {
                            model: {
                                let date = calendarContent.now;
                                let firstDay = new Date(date.getFullYear(), date.getMonth(), 1).getDay();
                                let daysInMonth = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
                                return firstDay + daysInMonth;
                            }
                            delegate: Rectangle {
                                width: 28; height: 28; radius: 14
                                property int dayNum: index - new Date(calendarContent.now.getFullYear(), calendarContent.now.getMonth(), 1).getDay() + 1
                                property bool isToday: dayNum === calendarContent.now.getDate()
                                color: isToday ? shellRoot.accentColor : "transparent"
                                visible: dayNum > 0
                                Text {
                                    anchors.centerIn: parent; text: parent.dayNum; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                                    font.bold: parent.isToday; color: parent.isToday ? shellRoot.backgroundColor : shellRoot.textColor; opacity: parent.isToday ? 1.0 : 0.8
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true } 
                }
            }
        }
    }
}