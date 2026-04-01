import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../components/"

PanelWindow {
    id: popupWindow

    anchors { top: true; right: true }
    
    margins { 
        top: 0 
        right: isShown ? 0 : -width 
    }
    
    
    width: 350 + 20
    
    implicitHeight: 120 + 20
    color: "transparent"
    
    Behavior on margins.right { 
        NumberAnimation { duration: 450; easing.type: Easing.OutQuart } 
    }

    exclusionMode: ExclusionMode.Normal
    aboveWindows: true

    property string summary: ""
    property string body: ""
    property bool isShown: false

    function restartTimer() {
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 5000 
        onTriggered: popupWindow.isShown = false
    }

    Item {
        id: wrapper
        anchors.fill: parent

        
        BarCorner {
            anchors.top: container.top
            anchors.right: container.left 
            position: "top-right"
            cornerRadius: 20
            shapeColor: shellRoot.backgroundColor
        }

        
        Rectangle {
            id: container
            width: 350
            implicitHeight: 120 
            anchors.top: parent.top
            anchors.right: parent.right
            color: shellRoot.backgroundColor
            radius: 20

            
            Rectangle { width: 20; implicitHeight: 20; color: parent.color; anchors.top: parent.top; anchors.left: parent.left }
            Rectangle { width: 20; implicitHeight: 20; color: parent.color; anchors.top: parent.top; anchors.right: parent.right }
            Rectangle { width: 20; implicitHeight: 20; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 5

                RowLayout {
                    spacing: 8
                    Text { text: "󰵚"; color: shellRoot.activeColor; font.pixelSize: 16 }
                    Text { 
                        text: "New Notification"
                        color: shellRoot.inactiveColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                    
                    MouseArea {
                        width: 20; implicitHeight: 20
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupWindow.isShown = false
                        Text { text: "󰅖"; color: shellRoot.inactiveColor; anchors.centerIn: parent }
                    }
                }

                Text {
                    text: popupWindow.summary
                    color: "white"
                    font.bold: true
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: popupWindow.body
                    color: "#b0b0b0"
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    Layout.fillWidth: true
                }

                MouseArea { anchors.fill: parent; onClicked: shellRoot.togglePanel("on") }
            }
        }

        
        BarCorner {
            anchors.top: container.bottom
            anchors.right: container.right
            position: "top-right"
            cornerRadius: 20
            shapeColor: shellRoot.backgroundColor
        }
    }
}