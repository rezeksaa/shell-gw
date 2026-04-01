import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell.Wayland
import Quickshell

Rectangle {
    id: root
    required property LockContext context
    
    color: "#141211"
    
    
    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.context.wallpaperPath ? "file://" + root.context.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        visible: root.context.wallpaperPath !== "" && status === Image.Ready
        
        onStatusChanged: {
            console.log("Wallpaper status:", status, "path:", root.context.wallpaperPath)
        }
        
        GaussianBlur {
            id: blurEffect
            anchors.fill: parent
            source: wallpaper
            radius: 40
            samples: 16
            cached: true
            visible: wallpaper.status === Image.Ready
        }
    }
    
    Rectangle {
        anchors.fill: parent
        visible: root.context.wallpaperPath === "" || wallpaper.status !== Image.Ready
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1a1a2e" }
            GradientStop { position: 0.5; color: "#16213e" }
            GradientStop { position: 1.0; color: "#0f3460" }
        }
    }
    
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.5
    }

    
    Rectangle {
        id: lockCard
        width: 420
        implicitHeight: contentLayout.implicitHeight + 80
        anchors.centerIn: parent
        color: shellRoot ? shellRoot.backgroundColor : "#141211"
        radius: shellRoot ? shellRoot.globalRadius : 20
        opacity: 0
        scale: 0.95
        
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 8
            radius: 32
            samples: 64
            color: Qt.rgba(0, 0, 0, 0.6)
        }
        
        ColumnLayout {
            id: contentLayout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 40
            }
            spacing: 20
            
            
            Label {
                id: clockLabel
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(new Date(), "hh:mm")
                color: shellRoot ? shellRoot.textColor : "#C6C8B0"
                font {
                    family: "JetBrains Mono" 
                    weight: Font.Light
                    pointSize: 64
                }
                renderType: Text.NativeRendering
                
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: {
                        clockLabel.text = Qt.formatTime(new Date(), "hh:mm")
                        dateLabel.text = Qt.formatDate(new Date(), "dddd, MMMM d")
                    }
                }
            }
            
            
            Label {
                id: dateLabel
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(new Date(), "dddd, MMMM d")
                color: shellRoot ? shellRoot.inactiveColor : "#666666"
                font {
                    family: "JetBrains Mono" 
                    pointSize: 14
                }
                renderType: Text.NativeRendering
            }

            
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 100
                Layout.preferredHeight: 100
                Layout.topMargin: 10
                Layout.bottomMargin: 10

                Image {
                    id: userImage
                    anchors.fill: parent
                    source: "file:///home/rezeke/.config/quickshell/assets/profilePicture.jpeg"
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 100; height: 100; radius: 50
                        }
                    }
                }
            }
            
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.1)
            }
            
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: shellRoot ? shellRoot.darkerGray : "#1c1c1a"
                radius: 12
                border.width: 2
                border.color: passwordField.activeFocus ? 
                    (shellRoot ? shellRoot.accentColor : "#D2D2B4") : Qt.rgba(1, 1, 1, 0.05)
                
                Behavior on border.color { ColorAnimation { duration: 150 } }
                
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 12; spacing: 8
                    
                    Label {
                        text: "\uf023"
                        color: passwordField.activeFocus ? 
                            (shellRoot ? shellRoot.accentColor : "#D2D2B4") : 
                            (shellRoot ? shellRoot.inactiveColor : "#666666")
                        font.family: "Font Awesome 6 Free Solid"
                        font.pointSize: 14
                    }
                    
                    TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Enter password..."
                        placeholderTextColor: shellRoot ? shellRoot.inactiveColor : "#666666"
                        color: shellRoot ? shellRoot.textColor : "#C6C8B0"
                        font.family: "JetBrains Mono" 
                        font.pointSize: 12
                        echoMode: TextInput.Password
                        background: null
                        verticalAlignment: Text.AlignVCenter
                        focus: true
                        enabled: !root.context.unlockInProgress
                        
                        onTextChanged: root.context.currentText = this.text
                        onAccepted: root.context.tryUnlock()
                    }
                    
                    Button {
                        id: unlockBtn
                        Layout.preferredWidth: 36; Layout.preferredHeight: 36
                        visible: root.context.currentText !== ""
                        enabled: !root.context.unlockInProgress
                        background: Rectangle {
                            color: unlockBtn.pressed ? 
                                Qt.darker(shellRoot ? shellRoot.accentColor : "#D2D2B4", 1.2) : 
                                unlockBtn.hovered ? (shellRoot ? shellRoot.accentColor : "#D2D2B4") : Qt.rgba(1, 1, 1, 0.1)
                            radius: 8
                        }
                        contentItem: Label {
                            text: root.context.unlockInProgress ? "\uf110" : "\uf09c"
                            color: shellRoot ? shellRoot.backgroundColor : "#141211"
                            font.family: "Font Awesome 6 Free Solid"
                            font.pointSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            RotationAnimation on rotation {
                                running: root.context.unlockInProgress; from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                            }
                        }
                        onClicked: root.context.tryUnlock()
                    }
                }
            }
            
            Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.context.showFailure
                text: "\uf071  Incorrect password"
                color: "#FF6B6B"
                font.pointSize: 12
                font.family: "JetBrains Mono" 
            }
            
            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                text: "Press Enter to unlock"
                color: Qt.rgba(1, 1, 1, 0.3)
                font.pointSize: 11
                font.family: "JetBrains Mono" 
            }
        }
        
        NumberAnimation on opacity { from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
        NumberAnimation on scale { from: 0.95; to: 1; duration: 400; easing.type: Easing.OutCubic }
    }
    
    Keys.onPressed: (event) => {
        if (!passwordField.activeFocus && event.key !== Qt.Key_Escape && event.key !== Qt.Key_Return) {
            passwordField.forceActiveFocus()
            if (event.text.length > 0) {
                root.context.currentText += event.text
            }
        }
    }
    
    focus: true
}