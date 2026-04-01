import QtQuick
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland

import "."
import "../components/"
import "../widgets/"
import "../settings/"
import "../popups/"
import "../panels/"
import "../shell/"

PanelWindow {
    id: sideBarWindow
    
    anchors { top: true; bottom: true; right: true }
    margins { top: 0; bottom: 0; right: shouldBeVisible ? 0 : -400 }
    color: "transparent"
    width: 400 + 20 

    focusable: true
    
    readonly property bool shouldBeVisible: shellRoot.showActivePanel
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayershell.Top

    onShouldBeVisibleChanged: {
        if (!shouldBeVisible && stackView.depth > 1) {
            stackView.pop(null) 
        }
    }

    function clearAllNotifications() {
        notificationModel.clear()
    }

    Item {
        id: wrapper
        anchors.fill: parent
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }

        BarCorner {
            anchors.top: parent.top; anchors.right: container.left 
            position: "top-right"; cornerRadius: 20
            shapeColor: shellRoot.backgroundColor
        }

        BarCorner {
            anchors.bottom: parent.bottom; anchors.right: container.left
            position: "bottom-right"; cornerRadius: 20
            shapeColor: shellRoot.backgroundColor
        }

        Rectangle {
            id: container
            width: 400
            anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right
            color: shellRoot.backgroundColor
            
            
            
            
            focus: sideBarWindow.shouldBeVisible

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    if (stackView.depth > 1) {
                        stackView.pop();
                    } else {
                        shellRoot.togglePanel();
                    }
                    event.accepted = true;
                }
            }

            StackView {
                id: stackView
                anchors.fill: parent
                initialItem: dashboardComponent
                clip: true 

                popEnter: Transition { NumberAnimation { properties: "x"; from: -400; to: 0; duration: 300; easing.type: Easing.OutCubic } }
                popExit: Transition { NumberAnimation { properties: "x"; from: 0; to: 400; duration: 300; easing.type: Easing.OutCubic } }
                pushEnter: Transition { NumberAnimation { properties: "x"; from: 400; to: 0; duration: 300; easing.type: Easing.OutCubic } }
                pushExit: Transition { NumberAnimation { properties: "x"; from: 0; to: -400; duration: 300; easing.type: Easing.OutCubic } }
            }
        }
    }

    
    Component {
        id: detailComponent
        Item {
            property string sourceFile: "" 
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 25; spacing: 20
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "󰁍"; color: shellRoot.activeColor; font.pixelSize: 22; font.family: "JetBrainsMono Nerd Font"
                        MouseArea { anchors.fill: parent; onClicked: stackView.pop() }
                    }
                    Text { text: "Back"; color: shellRoot.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                    Item { Layout.fillWidth: true }
                }
                Loader { Layout.fillWidth: true; Layout.fillHeight: true; source: sourceFile }
            }
        }
    }

            Component {
            id: dashboardComponent
                Item {
                    Item {
                property var masterNode: Pipewire.defaultAudioSink

                PwObjectTracker { 
                    objects: masterNode ? [ masterNode ] : [] 
                }

                Connections {
                    target: sideBarWindow
                    function onVisibleChanged() {
                        if (sideBarWindow.visible) {
                            masterNode = Pipewire.defaultAudioSink
                        }
                    }
                }
            }
            
            PwObjectTracker { objects: [ masterNode ] }

            property int currentBrightness: 0
            property string uptimeStr: "0m"
            property string wifiSSID: "Offline"
            property string wifiStatus: "Disconnected"
            property string powerProfile: "balanced"

            Process {
                id: getPowerProfile
                command: ["powerprofilesctl", "get"]
                running: sideBarWindow.shouldBeVisible
                stdout: StdioCollector { onTextChanged: powerProfile = text.trim() }
            }

            Process { id: setPowerProfile; onExited: getPowerProfile.running = true }

            function updateProfile(name) {
                setPowerProfile.command = ["powerprofilesctl", "set", name];
                setPowerProfile.running = true;
            }

            Process {
                id: getWifiDashboard
                command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2"]
                running: sideBarWindow.shouldBeVisible
                stdout: StdioCollector {
                    onTextChanged: {
                        let ssid = text.trim();
                        wifiSSID = ssid !== "" ? ssid : "Offline";
                        wifiStatus = ssid !== "" ? "Connected" : "Disconnected";
                    }
                }
            }

            Process {
                id: getUptime
                command: ["sh", "-c", "uptime -p | sed 's/up //; s/ hours,/h/; s/ minutes/m/; s/ minute/m/; s/ hour,/h/'"]
                running: sideBarWindow.shouldBeVisible
                stdout: StdioCollector { onTextChanged: uptimeStr = text.trim() }
            }

            Process {
                id: getBrightness
                command: ["brightnessctl", "i", "-m"]
                running: sideBarWindow.shouldBeVisible
                stdout: StdioCollector {
                    onTextChanged: {
                        var parts = text.split(',');
                        if (parts.length >= 4) currentBrightness = parseInt(parts[3]);
                    }
                }
            }
            Process { id: setBrightness }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 25; spacing: 20

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "󰣇"; color: shellRoot.activeColor; font.pixelSize: 22; font.family: "JetBrainsMono Nerd Font" }
                    Text { text: "Up " + uptimeStr; color: shellRoot.inactiveColor; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 15
                        Text { text: ""; color: shellRoot.activeColor; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.toggleSetting() }}
                        Text { text: "󰐥"; color: shellRoot.activeColor; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.togglePowerMenu() }}
                    }
                }

                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: shellRoot.inactiveColor; opacity: 0.2 }

                ColumnLayout {
                    spacing: 15; Layout.fillWidth: true
                    Item {
                        Layout.fillWidth: true; implicitHeight: dashboardMixer.implicitHeight
                        MixerEntry { id: dashboardMixer; node: Pipewire.defaultAudioSink; anchors.fill: parent }
                        MouseArea {
                            anchors.fill: parent; acceptedButtons: Qt.RightButton | Qt.MiddleButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) stackView.push(detailComponent, { "sourceFile": "../settings/VolumeContent.qml" })
                                else if (mouse.button === Qt.MiddleButton && masterNode.bound) masterNode.audio.muted = !masterNode.audio.muted
                            }
                        }
                    }

                    Rectangle {
                        id: brightnessBar
                        Layout.fillWidth: true; implicitHeight: 40; radius: 20; color: "#2A2A2A"; clip: true
                        Rectangle {
                            implicitHeight: parent.implicitHeight; width: parent.width * (currentBrightness / 100); radius: 20; color: "#D2D2B4"
                            Text { text: "󰃠"; anchors.right: parent.right; anchors.rightMargin: 15; anchors.verticalCenter: parent.verticalCenter; color: "#1B1B1B"; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font" }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            function updateBrightness(mouse) {
                                var percent = Math.round(Math.max(0, Math.min(1, mouse.x / width)) * 100);
                                currentBrightness = percent;
                                setBrightness.command = ["brightnessctl", "s", percent + "%"];
                                setBrightness.running = true;
                            }
                            onPressed: (mouse) => updateBrightness(mouse)
                            onPositionChanged: (mouse) => updateBrightness(mouse)
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: shellRoot.inactiveColor; opacity: 0.2 }

                GridLayout {
                    columns: 2; columnSpacing: 10; rowSpacing: 10; Layout.fillWidth: true
                    
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 70; radius: 25; color: "#2A2A2A"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 15; spacing: 5
                            Rectangle { width: 45; implicitHeight: 45; radius: 22.5; color: "#3D3D33"; Text { text: "󰖩"; anchors.centerIn: parent; color: "#D2D2B4"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font" } }
                            Column {
                                Text { text: wifiSSID.length > 7 ? wifiSSID.substring(0, 7) + "..." : wifiSSID; color: shellRoot.textColor; font.bold: true; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
                                Text { text: wifiStatus; color: shellRoot.inactiveColor; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: stackView.push(detailComponent, { "sourceFile": "../settings/WifiContent.qml" }) }
                    }

                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 70; radius: 25; color: "#2A2A2A"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 15; spacing: 5
                            Rectangle { width: 45; implicitHeight: 45; radius: 22.5; color: "#3D3D33"; Text { text: "󰂯"; anchors.centerIn: parent; color: "#D2D2B4"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font" } }
                            Column {
                                Text { text: "Bluetooth"; color: shellRoot.textColor; font.bold: true; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
                                Text { text: "Enabled"; color: shellRoot.inactiveColor; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: stackView.push(detailComponent, { "sourceFile": "../settings/BluetoothContent.qml" }) }
                    }

                    RowLayout {
                        Layout.fillWidth: true; Layout.columnSpan: 2; spacing: 15; Layout.topMargin: 10; Layout.bottomMargin: 5; Layout.leftMargin: 10; Layout.rightMargin: 10
                        RowLayout {
                            spacing: 12
                            Rectangle { 
                                width: 40; implicitHeight: 40; radius: 20; color: "#3D3D33"
                                Text { 
                                    text: powerProfile === "performance" ? "󰓅" : (powerProfile === "power-saver" ? "󰌪" : "󰗑")
                                    anchors.centerIn: parent; color: "#D2D2B4"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"
                                } 
                            }
                            Text { text: powerProfile; color: shellRoot.textColor; font.bold: true; font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font" }
                        }
                        Item { Layout.fillWidth: true }
                        RowLayout {
                            spacing: 10
                            Repeater {
                                model: [{p: "performance", i: "󰓅"}, {p: "balanced", i: "󰗑"}, {p: "power-saver", i: "󰌪"}]
                                delegate: Rectangle {
                                    width: 38; implicitHeight: 38; radius: 19
                                    color: powerProfile === modelData.p ? "#D2D2B4" : "#323232"
                                    scale: powerProfile === modelData.p ? 1.1 : 1.0
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                                    Text { text: modelData.i; anchors.centerIn: parent; color: powerProfile === modelData.p ? "#1B1B1B" : shellRoot.textColor; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font" }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: updateProfile(modelData.p) }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: shellRoot.inactiveColor; opacity: 0.2 }

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; color: "#161616"; radius: 20; clip: true
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 18; spacing: 12
                        ListView {
                            id: notifList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            
                            model: globalNotificationModel 
                            
                            spacing: 20
                            clip: true
                            
                            
                            delegate: ColumnLayout {
                                width: notifList.width
                                spacing: 8
                                
                                RowLayout {
                                    spacing: 8
                                    Text { text: "󰵚"; color: shellRoot.accentColor; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" }
                                    Text { text: model.appName; color: shellRoot.inactiveColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                                    Text { text: "•"; color: shellRoot.inactiveColor; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
                                    Text { text: model.time; color: shellRoot.inactiveColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                                    Item { Layout.fillWidth: true }
                                }
                                
                                ColumnLayout {
                                    spacing: 4
                                    Text { 
                                        text: model.summary
                                        color: shellRoot.textColor
                                        font.bold: true
                                        font.pixelSize: 15
                                        font.family: "JetBrainsMono Nerd Font"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true 
                                    }
                                    Text { 
                                        text: model.body
                                        color: "#b0b0b0"
                                        font.pixelSize: 13
                                        font.family: "JetBrainsMono Nerd Font"
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                        maximumLineCount: 2 
                                    }
                                }
                            }
                            
                                                    
                        Text { 
                                anchors.centerIn: parent
                                visible: globalNotificationModel.count === 0 
                                text: "No active notifications"
                                color: shellRoot.inactiveColor
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 10
                            Text { text: notificationModel.count + " Notifications"; color: shellRoot.inactiveColor; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: 85; height: 32; radius: 16
                                color: shellRoot.isSilent ? "#D2D2B4" : "#323232"
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.isSilent = !shellRoot.isSilent }
                                RowLayout { 
                                    anchors.centerIn: parent; spacing: 5
                                    Text { text: shellRoot.isSilent ? "󰂛" : "󰂚"; color: shellRoot.isSilent ? "#1B1B1B" : shellRoot.textColor; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
                                    Text { text: "Silent"; color: shellRoot.isSilent ? "#1B1B1B" : shellRoot.textColor; font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font" } 
                                }
                            }
                            Rectangle {
                                width: 85; implicitHeight: 32; radius: 16; color: "#323232"
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: globalNotificationModel.clear() }
                                RowLayout { 
                                    anchors.centerIn: parent; spacing: 5
                                    Text { text: "󰃢"; color: shellRoot.textColor; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
                                    Text { text: "Clear"; color: shellRoot.textColor; font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font" } 
                                }
                            }
                        }
                    }
                }
            }


                Timer {
                    interval: 10000 
                    running: sideBarWindow.visible
                    repeat: true
                    onTriggered: {
                        getWifiDashboard.running = false; 
                        getWifiDashboard.running = true;  
                    }
                }

            Component.onCompleted: {
                getBrightness.running = true; getUptime.running = true; getWifiDashboard.running = true; getPowerProfile.running = true;

            }
        }
    }
}