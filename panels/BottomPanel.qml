import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects 
import "../components/"

PanelWindow {
    id: bottomPanel
    focusable: true 
    WlrLayershell.keyboardFocus: shellRoot.showBottomPanel ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors { bottom: true; left: true; right: true }
    
    
    margins { 
        bottom: shellRoot.showBottomPanel ? 0 : -600 
    }

    Behavior on margins.bottom {
        NumberAnimation { 
            duration: 500; 
            easing.type: Easing.OutQuint 
        }
    }

    aboveWindows: true
    height: shellRoot.bottomPanelMode === "launcher" ? 600 : 200 
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    Item {
        id: wrapper
        width:  shellRoot.bottomPanelMode === "launcher" ? 650 + 80 : 1000 + 80 
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter

        BarCorner {
            width: 40; height: 40
            anchors.bottom: parent.bottom; anchors.right: container.left
            position: "bottom-right"; cornerRadius: 20; shapeColor: shellRoot.backgroundColor
        }

        BarCorner {
            width: 40; height: 40
            anchors.bottom: parent.bottom; anchors.left: container.right
            position: "bottom-left"; cornerRadius: 20; shapeColor: shellRoot.backgroundColor
        }

        Rectangle {
            id: container
            width: shellRoot.bottomPanelMode === "launcher" ? 550 : 1000
            height: parent.height
            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
            color: shellRoot.backgroundColor
            
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Item {
                    width: container.width; height: container.height
                    Rectangle {
                        anchors.top: parent.top 
                        width: parent.width; height: parent.height + 80
                        radius: shellRoot.globalRadius
                    }
                }
            }

            
            Loader {
                id: contentLoader
                anchors.fill: parent
                anchors.margins: 20
                
                source: {
                    if (shellRoot.bottomPanelMode === "launcher") return "../popups/AppLauncher.qml"
                    if (shellRoot.bottomPanelMode === "wallpaper") return "../settings/WallpaperSelector.qml"
                    return ""
                }
                
                onLoaded: item.forceActiveFocus()
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    shellRoot.showBottomPanel = false;
                    
                    event.accepted = true;
                }
            }
        }
    }
}