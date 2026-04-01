import QtQuick
import QtQuick.Layouts 1.12
import Quickshell
import QtQuick.Controls
import Quickshell.Io

ColumnLayout {
    id: wifiContent
    
    width: 310 
    spacing: 15
    
    Layout.alignment: Qt.AlignTop 

    
    ListModel { id: wifiModel }

    Process {
        id: wifiScanProcess
        command: ["sh", "-c", "nmcli -t -f SSID,SIGNAL,SECURITY,ACTIVE device wifi list"]
        stdout: StdioCollector {
            
            onStreamFinished: {
                wifiModel.clear();
                var lines = text.trim().split('\n');
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(':');
                    
                    if (parts.length >= 4 && parts[0] !== "" && parts[0] !== "--") {
                        wifiModel.append({
                            ssid: parts[0],
                            signal: parseInt(parts[1]),
                            security: parts[2],
                            active: parts[3] === "yes"
                        });
                    }
                }
            }
        }
    }

    Process { id: connectProcess }    
    
    
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
                    id: searchInput
                    Layout.fillWidth: true
                    color: shellRoot.textColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                    
                    
                    Text {
                        text: "Search SSID..."
                        color: shellRoot.inactiveColor
                        visible: !searchInput.text && !searchInput.activeFocus
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                }
            }
        }
        
        
        Text {
            id: refreshIcon
            text: "󰑐"
            color: wifiScanProcess.running ? shellRoot.accentColor : shellRoot.inactiveColor
            font.pixelSize: 20
            transformOrigin: Item.Center 

            
            MouseArea {
                anchors.fill: parent
                anchors.margins: -5
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    wifiScanProcess.running = false
                    wifiScanProcess.running = true
                }
            }

            
            RotationAnimator {
                target: refreshIcon
                from: 0; to: 360; duration: 800
                running: wifiScanProcess.running
                loops: Animation.Infinite
                easing.type: Easing.Linear
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: wifiModel
            delegate: Rectangle {
                visible: ssid.toLowerCase().includes(searchInput.text.toLowerCase())
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 45 : 0
                color: active ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                radius: 10
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    
                    Text {
                        text: signal > 75 ? "󰤨" : signal > 50 ? "󰤥" : "󰤢"
                        color: active ? shellRoot.activeColor : shellRoot.borderColor
                        font.pixelSize: 16
                    }

                    Text {
                        text: ssid
                        color: shellRoot.activeColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: active ? "Connected" : (security !== "" ? "󰌾" : "")
                        color: shellRoot.inactiveColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var cmd = "nmcli device wifi connect \"" + ssid + "\"";
                        connectProcess.command = ["sh", "-c", cmd];
                        connectProcess.running = true;
                    }
                }
            }
        }
    }

    
    
    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wifiScanProcess.running = true
    }
}