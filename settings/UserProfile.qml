import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Qt5Compat.GraphicalEffects
import QtCore

Item {
    id: userProfileRoot
    
    
    readonly property string profilePath: "file:///home/rezeke/.config/quickshell/assets/profilePicture.jpeg"
    
    property string timestamp: Date.now().toString()

    FileDialog {
        id: fileDialog
        title: "Select Profile Picture"
        nameFilters: ["Image files (*.jpg *.jpeg *.png *.png)"]
        currentFolder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
        
        onAccepted: {
            
            copyProcess.command = ["cp", "-f", selectedFile.toString().replace("file://", ""), "/home/rezeke/.config/quickshell/assets/profilePicture.jpeg"]
            copyProcess.running = true
        }
    }

    Process {
        id: copyProcess
        onExited: {
            
            userProfileRoot.timestamp = Date.now().toString()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 30

        ColumnLayout {
            spacing: 5
            Text {
                text: "User Profile"
                color: shellRoot.activeColor
                font.family: "JetBrains Mono"; font.pixelSize: 24; font.bold: true
            }
            Text {
                text: "Personalize your identity across the shell."
                color: shellRoot.inactiveColor
                font.family: "JetBrains Mono"; font.pixelSize: 12
            }
        }

        
        RowLayout {
            spacing: 25
            Layout.fillWidth: true

            
            Item {
                width: 120; height: 120
                Image {
                    id: avatarPreview
                    anchors.fill: parent
                    source: userProfileRoot.profilePath + "?t=" + userProfileRoot.timestamp
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle { width: 120; height: 120; radius: 60 }
                    }
                }
                
                Rectangle {
                    anchors.fill: parent; radius: 60; color: "black"
                    opacity: avatarMouse.containsMouse ? 0.4 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Text {
                        anchors.centerIn: parent; text: "󰄵"
                        color: "white"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 30
                        visible: avatarMouse.containsMouse
                    }
                    MouseArea { id: avatarMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: fileDialog.open() }
                }
            }

            ColumnLayout {
                spacing: 10
                
                Text {
                    
                    text: settingsApp.username
                    color: shellRoot.activeColor
                    font.family: "JetBrains Mono"; font.pixelSize: 18; font.bold: true
                }
                
                Button {
                    id: changePicBtn
                    onClicked: fileDialog.open()
                    
                    
                    contentItem: Text {
                        text: "Change Picture"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        color: shellRoot.activeColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter 
                        elide: Text.ElideRight
                    }
                    
                    background: Rectangle {
                        implicitWidth: 130
                        implicitHeight: 36 
                        color: changePicBtn.hovered ? shellRoot.gray : "transparent"
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                        border.width: 1
                        radius: 8
                    }
                }
            }
        }

        Item { Layout.fillHeight: true } 
    }
}