import Quickshell
import Quickshell.Wayland
import QtQuick

import "."
import "../components/"
import "../widgets/"
import "../settings/"
import "../popups/"
import "../panels/"
import "../shell/"

PanelWindow {
    id: root

    property int cornerR: 20 

    implicitWidth: WlrLayershell.width
    height: WlrLayershell.height

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        left: 0
        right: 0
    }

    exclusionMode: ExclusionMode.Normal
    focusable: false
    aboveWindows: true
    color: "transparent"
    mask: Region {}

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property color cornerC: "#1e1e2e"

    
    BarCorner {
        anchors {
            top: parent.top
            left: parent.left
        }
        position: "top-left"
        cornerRadius: root.cornerR
        shapeColor: shellRoot.backgroundColor
    }

    
    BarCorner {
        anchors {
            top: parent.top
            right: parent.right
        }
        position: "top-right"
        cornerRadius: root.cornerR
        shapeColor: shellRoot.backgroundColor
    }
    
    BarCorner {
        anchors {
            bottom: parent.bottom
            left: parent.left
        }
        position: "bottom-left"
        cornerRadius: root.cornerR
        shapeColor: shellRoot.backgroundColor
    }

    
    BarCorner {
        anchors {
            bottom: parent.bottom
            right: parent.right
        }
        position: "bottom-right"
        cornerRadius: root.cornerR
        shapeColor: shellRoot.backgroundColor
    }
}