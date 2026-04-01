import QtQuick
import QtQuick.Layouts 1.12

Rectangle {
    property string label: ""
    property string value: ""
    
    Layout.fillWidth: true
    implicitHeight: 55
    radius: 15
    color: shellRoot.gray

    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        Text { 
            text: label; 
            color: shellRoot.inactiveColor; 
            font.pixelSize: 12; 
            font.family: "JetBrainsMono Nerd Font" 
        }
        Item { Layout.fillWidth: true }
        Text { 
            text: value; 
            color: shellRoot.textColor; 
            font.bold: true; 
            font.pixelSize: 12; 
            font.family: "JetBrainsMono Nerd Font" 
        }
    }
}