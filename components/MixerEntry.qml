import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire

Rectangle {
id: cardRoot

required property PwNode node;

color: "transparent" 
radius: 8 

implicitWidth: mainLayout.implicitWidth + 32 
implicitHeight: mainLayout.implicitHeight + 24

PwObjectTracker { objects: [ node ] }

ColumnLayout {
    id: mainLayout
    anchors.fill: parent
    anchors.margins: 5
    spacing: 15

    RowLayout {
        spacing: 12 
        Layout.alignment: Qt.AlignVCenter

        AnimatedImage {
            id: myGif
            source: "file:///home/rezeke/.config/quickshell/assets/kurukuru.gif"
            sourceSize.width: 24
            sourceSize.height: 24
            Layout.rightMargin: 5
        }

        Label {
            text: {
                const app = node.properties["application.name"] ?? (node.description != "" ? node.description : node.name);
                const media = node.properties["media.name"];
                return media != undefined ? `${app} - ${media}` : app;
            }
            font.family: "JetBrainsMono Nerd Font"
            color:  shellRoot.textColor
            Layout.fillWidth: true
            elide: Text.ElideRight
            font.bold: true
        }

        
        Label {
            text: `${Math.floor(node.audio.volume * 100)}%`
            color: shellRoot.inactiveColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
        }
    }

    
    Slider {
        id: control
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        value: node.audio.volume
        onMoved: node.audio.volume = value

        background: Rectangle {
            implicitHeight: 40
            width: control.availableWidth
            radius: implicitHeight / 2
            color: "#2A2A2A" 
            clip: true 

            Rectangle {
    width: control.position * parent.width
    implicitHeight: parent.implicitHeight
    radius: parent.radius
    
    
    color: node.audio.muted ? "#444444" : shellRoot.textColor 
    
    Behavior on color { ColorAnimation { duration: 200 } }

    Text {
        text: node.audio.muted ? "󰝟" : "󰕾"
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        color: "#1B1B1B" 
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        opacity: control.position > 0.1 ? 1 : 0
    }
}
        }

        handle: Item { width: 1; implicitHeight: 1 } 
    }
}

}