import QtQuick
import QtQuick.Layouts 1.12

ColumnLayout {
    property string label: ""
    property real percent: 0.0
    property string valueText: ""
    
    Layout.fillWidth: true
    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        Text { 
            text: label; 
            color: shellRoot.inactiveColor; 
            font.pixelSize: 11; 
            font.family: "JetBrainsMono Nerd Font" 
        }
        Item { Layout.fillWidth: true }
        Text { 
            text: valueText; 
            color: shellRoot.textColor; 
            font.pixelSize: 11; 
            font.family: "JetBrainsMono Nerd Font" 
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 6
        radius: 3
        color: "#252525"
        Rectangle {
            width: parent.width * percent
            implicitHeight: parent.implicitHeight
            radius: 3
            color: shellRoot.textColor
        }
    }
}