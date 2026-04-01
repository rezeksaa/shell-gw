import QtQuick
import QtQuick.Layouts 1.12
import Quickshell
import Quickshell.Wayland

PanelWindow {
id: dialogWindow

screen: Quickshell.screens[0]



width: 350
implicitHeight: 180
color: "transparent"


property string title: "Confirm Action"
property string message: "Are you sure you want to proceed?"
property var onAccept: null


visible: shellRoot.isConfirmDialogOpen

Rectangle {
    anchors.fill: parent
    color: shellRoot.backgroundColor
    radius: 20
    border.color: shellRoot.gray
    border.width: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 15

        Text {
            text: dialogWindow.title
            color: shellRoot.activeColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: dialogWindow.message
            color: "white"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 15

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40; radius: 10; color: shellRoot.gray
                Text { anchors.centerIn: parent; text: "Cancel"; color: "white"; font.family: "JetBrainsMono Nerd Font"; font.bold: true }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: shellRoot.isConfirmDialogOpen = false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40; radius: 10; color: "#ff5555"
                Text { anchors.centerIn: parent; text: "Confirm"; color: "white"; font.family: "JetBrainsMono Nerd Font"; font.bold: true }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (dialogWindow.onAccept) dialogWindow.onAccept();
                        shellRoot.isConfirmDialogOpen = false;
                    }
                }
            }
        }
    }
}

}