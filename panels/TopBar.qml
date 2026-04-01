import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland 
import Quickshell.Services.Mpris 

PanelWindow {
    id: topBar
    anchors { top: true; left: true; right: true }
    implicitHeight: 35
    color: "transparent"
    aboveWindows: true 

    SystemClock { id: barClock; precision: SystemClock.Minutes }
    readonly property int batVal: parseInt(batteryLevel.text.trim()) || 0
    WlrLayershell.layer: WlrLayershell.Top

    function toRoman(num) {
        const map = { 1: "I", 2: "II", 3: "III", 4: "IV", 5: "V", 6: "VI", 7: "VII", 8: "VIII", 9: "IX", 10: "X" };
        return map[num] || num;
    }

    Process {
        id: batteryProcess
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity"]
        running: true
        stdout: StdioCollector { id: batteryLevel }
    }

    Timer { interval: 30000; running: true; repeat: true; onTriggered: batteryProcess.running = true }

    Rectangle {
        id: barContainer
        anchors.fill: parent
        color: shellRoot.backgroundColor

        Rectangle {
            id: bottomBorder
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: shellRoot.globalBorderWidth
            color: shellRoot.borderColor
            z: 1
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15; anchors.rightMargin: 15
            spacing: 15

            
            RowLayout {
                spacing: 25
                
                Text {
                    text: "󰣇" 
                    color: shellRoot.activeLeftPanel !== false ? shellRoot.activeColor : shellRoot.borderColor
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: shellRoot.toggleLeftPanel()
                    }
                }

                
                Rectangle {
                    id: workspaceOuterPill
                    implicitHeight: 26
                    radius: 13
                    color: shellRoot.gray
                    Layout.preferredWidth: wsRow.width + 20 
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        id: pill
                        implicitHeight: 20
                        radius: 10
                        color: shellRoot.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                        z: 1 

                        property var activeItem: null
                        x: activeItem ? (activeItem.x + wsRow.x) : 0
                        width: activeItem ? activeItem.width : 0

                        Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
                        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
                    }

                    Row {
                        id: wsRow
                        anchors.centerIn: parent
                        spacing: 2
                        z: 2 

                        Repeater {
                            model: [...Hyprland.workspaces.values].sort((a, b) => a.id - b.id)
                            delegate: Item {
                                id: delegateRoot
                                width: wsText.width + 16
                                implicitHeight: 20
                                
                                readonly property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData.id

                                onIsActiveChanged: if (isActive) pill.activeItem = delegateRoot
                                Component.onCompleted: if (isActive) pill.activeItem = delegateRoot

                                Text {
                                    id: wsText
                                    anchors.centerIn: parent
                                    text: toRoman(modelData.id)
                                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true
                                    color: delegateRoot.isActive ? shellRoot.backgroundColor : shellRoot.inactiveColor
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true } 

            
            RowLayout {
                spacing: 10 

                Rectangle {
                    id: batteryPill
                    height: 26
                    radius: 13
                    color: shellRoot.gray
                    Layout.preferredWidth: batteryRow.width + 20

                    RowLayout {
                        id: batteryRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: batVal + "%"
                            color: shellRoot.borderColor
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true
                        }

                        Item {
                            width: 20; height: 20
                            Rectangle {
                                anchors.fill: parent; radius: 10
                                color: "transparent"; border.color: shellRoot.borderColor; border.width: 2; opacity: 0.15
                            }
                            Canvas {
                                id: batteryCanvas
                                anchors.fill: parent; antialiasing: true
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset();
                                    var centerX = width / 2; var centerY = height / 2; var radius = (width - 2) / 2;
                                    ctx.beginPath();
                                    ctx.strokeStyle = batVal <= 20 ? "#ff5555" : shellRoot.accentColor;
                                    ctx.lineWidth = 2; ctx.lineCap = "round";
                                    var startAngle = -Math.PI / 2;
                                    var endAngle = startAngle + (batVal / 100) * (Math.PI * 2);
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                                    ctx.stroke();
                                }
                                Connections {
                                    target: batteryLevel
                                    function onTextChanged() { batteryCanvas.requestPaint(); }
                                }
                            }
                            Text {
                                anchors.centerIn: parent; text: "󰁹" 
                                color: shellRoot.borderColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10
                            }
                        }
                    }
                }

                Rectangle {
                    id: settingsPill
                    implicitHeight: 26
                    radius: 13
                    color: shellRoot.gray
                    Layout.preferredWidth: settingsRow.width + 24 

                    RowLayout {
                        id: settingsRow
                        anchors.centerIn: parent
                        spacing: 15 

                        Repeater {
                            model: [
                                { icon: "󰕾", panel: "volume" },
                                { icon: "󰃠", panel: "brightness" },
                                { icon: "󰖩", panel: "wifi" },
                                { icon: "󰂯", panel: "bt" },
                                { icon: "󰵙", panel: "notifications" }
                            ]
                            delegate: Text {
                                text: modelData.icon
                                color: shellRoot.activePanel === modelData.panel ? shellRoot.activeColor : shellRoot.borderColor
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.togglePanel()
                                }
                            }
                        }
                    }
                }
            }
        }

        
        RowLayout {
            id: centerGroup
            anchors.centerIn: parent
            spacing: 10 

            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: shellRoot.showWidgets = !shellRoot.showWidgets
            }

            Rectangle {
                id: mediaPill
                implicitHeight: 26
                radius: 13
                color: shellRoot.gray
                Layout.preferredWidth: mediaRow.width + 20 

                RowLayout {
                    id: mediaRow
                    anchors.centerIn: parent
                    spacing: 8
                    
                    readonly property var activePlayer: {
                        const players = Mpris.players.values;
                        return players.find(p => p.identity.toLowerCase().includes("spotify")) || null;
                    }
                    readonly property bool hasMedia: activePlayer !== null && activePlayer.trackTitle !== ""

                    Text { 
                        text: parent.hasMedia ? "󰓇" : "󰎆" 
                        color: shellRoot.borderColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 
                    }

                    Text {
                        text: parent.hasMedia 
                            ? (parent.activePlayer.trackArtist ? parent.activePlayer.trackArtist + " - " : "") + parent.activePlayer.trackTitle 
                            : "no media"
                        color: parent.hasMedia && shellRoot.showWidgets ? shellRoot.activeColor : shellRoot.borderColor
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true
                        Layout.maximumWidth: 150; elide: Text.ElideRight 
                    }
                }
            }

            
            Rectangle {
                id: windowPill
                implicitHeight: 26
                radius: 13
                color: shellRoot.gray
                Layout.preferredWidth: Math.min(windowTitleText.implicitWidth + 24, 300)

                Text {
                    id: windowTitleText
                    anchors.centerIn: parent
                    
                    
                    readonly property bool validWindowOnWorkspace: Hyprland.activeToplevel && 
                                                                    Hyprland.focusedWorkspace && 
                                                                    Hyprland.activeToplevel.workspace.id === Hyprland.focusedWorkspace.id && 
                                                                    Hyprland.activeToplevel.title !== ""

                    text: validWindowOnWorkspace ? Hyprland.activeToplevel.title : "what's on your mind?"
                    
                    color: shellRoot.activeColor 
                           
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true
                    width: parent.width - 24; elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                } 
            }

            Rectangle {
                id: clockPill
                implicitHeight: 26
                radius: 13
                color: shellRoot.gray
                Layout.preferredWidth: clockRow.width + 20

                RowLayout {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "󱑊"; color: shellRoot.borderColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                    Text {
                        text: Qt.formatDateTime(barClock.date, "hh:mm AP") + " • " + Qt.formatDateTime(barClock.date, "dd/MM")
                        color: shellRoot.borderColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true
                    }
                }
            }
        }
    }
}