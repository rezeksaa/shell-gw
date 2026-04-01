import QtQuick
import QtQuick.Layouts 1.12
import Quickshell
import QtQuick.Controls
import Quickshell.Io

ColumnLayout {
    id: bluetoothContent
    
    
    
    Layout.fillWidth: true 
    spacing: 15
    Layout.alignment: Qt.AlignTop 

    ListModel { id: btModel }

    
    Process {
        id: btListProcess
        command: ["sh", "-c", "bluetoothctl devices | while read -r _ mac name; do info=$(bluetoothctl info $mac); connected=$(echo \"$info\" | grep -q \"Connected: yes\" && echo \"connected\" || echo \"paired\"); alias=$(echo \"$info\" | grep \"Alias:\" | cut -d ' ' -f 2-); echo \"$connected:$alias:$mac\"; done"]
        stdout: StdioCollector {
            onTextChanged: {
                btModel.clear();
                var lines = text.trim().split('\n');
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(':');
                    if (parts.length >= 3) {
                        btModel.append({
                            status: parts[0],
                            name: parts[1].trim() || "Unknown Device",
                            mac: parts[2]
                        });
                    }
                }
            }
        }
    }

    Process { id: btActionProcess }

    
    RowLayout {
        Layout.fillWidth: true
        spacing: 12 

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 10
            color: shellRoot.gray 

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Text {
                    text: "󰍉"
                    color: shellRoot.inactiveColor
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                }

                TextInput {
                    id: btSearchInput
                    Layout.fillWidth: true
                    color: shellRoot.textColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                    
                    Text {
                        text: "Search devices..."
                        color: shellRoot.inactiveColor
                        visible: !btSearchInput.text && !btSearchInput.activeFocus
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                }
            }
        }
        
        Text {
            id: refreshIcon
            text: "󰑐"
            color: btListProcess.running ? shellRoot.accentColor : shellRoot.inactiveColor
            font.pixelSize: 20
            transformOrigin: Item.Center 

            MouseArea {
                anchors.fill: parent
                anchors.margins: -5
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    btListProcess.running = false
                    btListProcess.running = true
                }
            }

            RotationAnimator {
                target: refreshIcon
                from: 0; to: 360; duration: 800
                running: btListProcess.running
                loops: Animation.Infinite
                easing.type: Easing.Linear
            }
        }
    }

    
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: btModel
            delegate: Rectangle {
                visible: name.toLowerCase().includes(btSearchInput.text.toLowerCase())
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 55 : 0 
                color: status === "connected" ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                radius: 10

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    spacing: 15

                    
                    Text {
                        text: name.toLowerCase().includes("headphone") || name.toLowerCase().includes("audio") ? "󰋋" : "󰂯"
                        color: status === "connected" ? shellRoot.accentColor : shellRoot.inactiveColor
                        font.pixelSize: 20
                    }

                    
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true 
                        
                        Text {
                            text: name
                            color: shellRoot.activeColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: mac
                            color: shellRoot.inactiveColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                    }

                    
                    Text {
                        text: status === "connected" ? "Connected" : ""
                        color: shellRoot.inactiveColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var action = status === "connected" ? "disconnect" : "connect";
                        btActionProcess.command = ["bluetoothctl", action, mac];
                        btActionProcess.running = true;
                        refreshTimer.start();
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true; Layout.fillWidth: true }

    Timer { id: refreshTimer; interval: 3000; onTriggered: btListProcess.running = true }
    Timer { interval: 15000; running: true; repeat: true; triggeredOnStart: true; onTriggered: btListProcess.running = true }
}