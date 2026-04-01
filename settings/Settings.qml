import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

FloatingWindow {
    id: settingsApp
    
    width: 750 
    height: 500
    color: "transparent" 
    
    
    property string username: "User"
    
    Process {
        command: ["whoami"]
        running: true
        stdout: StdioCollector { 
            onStreamFinished: settingsApp.username = text.trim() 
        }
    }

    property int currentTab: 0

    
    Rectangle {
        anchors.fill: parent
        color: shellRoot.backgroundColor
        radius: shellRoot.globalRadius
        clip: true
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        
        Text {
            id: closeBtn
            text: "󰅖" 
            color: shellRoot.activeColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            z: 10 
            anchors { top: parent.top; right: parent.right; topMargin: 15; rightMargin: 15 }

            MouseArea {
                id: closeBtnMouse
                anchors.fill: parent; anchors.margins: -10
                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                onClicked: shellRoot.settingActive = false
            }
            opacity: closeBtnMouse.containsMouse ? 1.0 : 0.5
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 240 
                color: Qt.rgba(0, 0, 0, 0.2)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20 
                    spacing: 15

                    Text {
                        text: "Settings"
                        color: shellRoot.activeColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11; font.bold: true
                        opacity: 0.4
                        Layout.bottomMargin: 10
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 10
                        spacing: 8

                        component TabButton: Rectangle {
                            property string icon: ""
                            property string label: ""
                            property int tabIndex: 0
                            
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 10
                            color: settingsApp.currentTab === tabIndex ? shellRoot.gray : "transparent"
                            
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; spacing: 12
                                Text { 
                                    text: icon; color: settingsApp.currentTab === tabIndex ? shellRoot.accentColor : shellRoot.inactiveColor
                                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 
                                }
                                Text { 
                                    text: label; color: settingsApp.currentTab === tabIndex ? shellRoot.activeColor : shellRoot.textColor
                                    font.family: "JetBrains Mono"; font.pixelSize: 12 
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsApp.currentTab = tabIndex
                            }
                        }

                        TabButton { icon: "󰋚"; label: "User Profile"; tabIndex: 0 }
                        TabButton { icon: "󰖩"; label: "Network"; tabIndex: 1 }
                        TabButton { icon: "󰂯"; label: "Bluetooth"; tabIndex: 2 }
                        TabButton { icon: "󰵙"; label: "Notifications"; tabIndex: 3 }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                StackLayout {
                    id: contentStack
                    anchors.fill: parent
                    
                    
                    
                    anchors.topMargin: settingsApp.currentTab === 0 ? 20 : 60
                    
                    anchors.leftMargin: 40
                    anchors.rightMargin: 40
                    anchors.bottomMargin: 20
                    currentIndex: settingsApp.currentTab

                    
                    Behavior on anchors.topMargin {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    
                    Loader {
                        source: "UserProfile.qml"
                        active: true 
                    }

                    
                    Loader {
                        source: "WifiContent.qml"
                        active: contentStack.currentIndex === 1
                    }

                    
                    Loader {
                        source: "BluetoothContent.qml"
                        active: contentStack.currentIndex === 2
                    }

                    
                    ColumnLayout {
                        spacing: 25

                        ColumnLayout {
                            spacing: 5
                            Text { 
                                text: "Notifications"
                                color: "white"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 22; font.bold: true 
                            }
                            Text { 
                                text: "Manage how alerts and popups behave."
                                color: shellRoot.inactiveColor
                                font.family: "JetBrains Mono"; font.pixelSize: 12 
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.1) }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 20
                            ColumnLayout {
                                spacing: 2
                                Text { text: "Silent Mode (Do Not Disturb)"; color: shellRoot.textColor; font.family: "JetBrains Mono"; font.pixelSize: 14; font.bold: true }
                                Text { text: "When enabled, incoming notification popups are hidden."; color: shellRoot.inactiveColor; font.family: "JetBrains Mono"; font.pixelSize: 11 }
                            }
                            Item { Layout.fillWidth: true } 
                            Switch {
                                id: silentSwitch
                                checked: shellRoot.isSilent
                                onToggled: shellRoot.isSilent = checked
                                indicator: Rectangle {
                                    implicitWidth: 46; implicitHeight: 24; radius: 12
                                    color: silentSwitch.checked ? shellRoot.accentColor : shellRoot.gray
                                    Rectangle {
                                        x: silentSwitch.checked ? parent.width - width - 3 : 3
                                        y: 3; width: 18; height: 18; radius: 9
                                        color: silentSwitch.checked ? "#1B1B1B" : shellRoot.inactiveColor
                                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
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
}