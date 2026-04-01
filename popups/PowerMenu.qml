import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Wayland
import QtQuick.Layouts

PanelWindow {
    id: powerPanel
    
    
    width: 220
    implicitHeight: 220
    
    focusable: true
    aboveWindows: true
    
    color: "transparent"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive 

    Rectangle {
        anchors.fill: parent
        color: shellRoot.backgroundColor
        radius: shellRoot.globalRadius
        border.width: 1
        border.color: shellRoot.gray

        GridView {
            id: powerGrid
            anchors.fill: parent
            anchors.margins: 20
            
            model: powerModel
            currentIndex: 0
            
            
            cellWidth: 90
            cellHeight: 90

            
            focus: true
            keyNavigationEnabled: true

            delegate: Item {
                width: powerGrid.cellWidth
                implicitHeight: powerGrid.cellHeight
                readonly property bool isSelected: GridView.isCurrentItem

                Rectangle {
                    anchors.centerIn: parent
                    width: 75; implicitHeight: 75
                    radius: 20
                    color: isSelected ? shellRoot.gray : "transparent"
                    border.width: isSelected ? 1 : 0
                    border.color: shellRoot.accentColor

                    Text {
                        anchors.centerIn: parent
                        text: icon
                        color: isSelected ? shellRoot.activeColor : shellRoot.accentColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 32
                        
                        scale: isSelected ? 1.15 : 1.0
                        Behavior on scale { NumberAnimation { duration: 200 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            powerGrid.currentIndex = index
                            executePowerAction(action, name)
                        }
                    }
                }
            }

            
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { 
                    let item = powerModel.get(currentIndex);
                    executePowerAction(item.action, item.name);
                    event.accepted = true;
                }
                if (event.key === Qt.Key_Escape) {
                    shellRoot.powerMenuActive = false;
                    event.accepted = true;
                }
                
            }
        }
    }

    
    ListModel {
        id: powerModel
        ListElement { name: "Shutdown"; icon: "󰐥"; action: "systemctl poweroff" }
        ListElement { name: "Reboot";   icon: "󰜉"; action: "systemctl reboot" }
        ListElement { name: "Logout";   icon: "󰍃"; action: "hyprctl dispatch exit" }
        ListElement { name: "Lock";     icon: "󰌾"; action: "hyprlock" }
    }

    function executePowerAction(cmd, name) {
        shellRoot.powerMenuActive = false;
        Quickshell.execDetached([
            "bash", "-c", 
            "notify-send -t 2000 'System' 'Executing " + name + "...'; " + cmd
        ]);
    }

    
    onVisibleChanged: if (visible) powerGrid.forceActiveFocus()
}