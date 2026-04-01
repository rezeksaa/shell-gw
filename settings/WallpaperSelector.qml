import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: wallpaperRoot
    anchors.fill: parent
    focus: true 

    property string activeWallpaperPath: ""
    property bool isInitialLoad: true 

    ListModel { id: wallpaperModel }

    
    Timer {
        id: applyTimer
        interval: 100 
        repeat: false
        onTriggered: {
            if (wallpaperModel.count > 0) {
                previewWallpaper(wallpaperModel.get(wallList.currentIndex).path);
            }
        }
    }

    Process {
        id: currentWallQuery
        command: ["bash", "-c", "swww query | awk -F'image: ' '{print $2}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                activeWallpaperPath = this.text.trim();
                findAndSelectCurrent();
            }
        }
    }

    Process {
        id: wallScanner
        command: ["bash", "-c", "find /home/" + Quickshell.env("USER") + "/Pictures/Wallpapers -type f -regex '.*\\.\\(jpg\\|jpeg\\|png\\|webp\\)' | sort"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                wallpaperModel.clear();
                let lines = text.trim().split("\n");
                for (let path of lines) {
                    if (path !== "") wallpaperModel.append({ "path": path });
                }
                currentWallQuery.running = true;
            }
        }
    }

    function findAndSelectCurrent() {
        if (!activeWallpaperPath) return;
        
        for (let i = 0; i < wallpaperModel.count; i++) {
            if (wallpaperModel.get(i).path === activeWallpaperPath) {
                wallList.currentIndex = i;
                Qt.callLater(() => { 
                    wallList.positionViewAtIndex(i, ListView.Center);
                    isInitialLoad = false;
                });
                break;
            }
        }
    }

    ListView {
        id: wallList
        anchors.fill: parent
        anchors.margins: 10 
        orientation: ListView.Horizontal
        spacing: 15
        model: wallpaperModel
        clip: true
        
        header: Item { width: (wallList.width - 220) / 2 }
        footer: Item { width: (wallList.width - 220) / 2 }

        
        highlightMoveDuration: 150   
        highlightResizeDuration: 150
        
        snapMode: ListView.SnapToItem
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: (width / 2) - 110
        preferredHighlightEnd: (width / 2) + 110
        
        currentIndex: 0

        onCurrentIndexChanged: {
            if (!isInitialLoad) {
                applyTimer.restart();
            }
        }

        delegate: Item {
            id: wallDelegate
            width: 220
            implicitHeight: wallList.height 
            readonly property bool isSelected: ListView.isCurrentItem

            Column {
                anchors.centerIn: parent
                spacing: 8
                scale: wallDelegate.isSelected ? 1.05 : 0.9
                Behavior on scale { NumberAnimation { duration: 150 } } 

                Rectangle {
                    width: 220; implicitHeight: 140; radius: 12
                    color: shellRoot.gray; clip: true

                    Image {
                        anchors.fill: parent
                        source: "file://" + path
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: wallDelegate.isSelected ? 1.0 : 0.4
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    wallList.currentIndex = index;
                }
            }
        }
    }

    function previewWallpaper(file) {
        Quickshell.execDetached([
            "swww", "img", file, 
            "--transition-type", "grow", 
            "--transition-step", "255", 
            "--transition-fps", "60", 
            "--transition-duration", "1.5", 
            "--transition-pos", "bottom"
        ]);
    }

    function selectAndClose() {
        shellRoot.closeAllPanels(); 
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Right) { wallList.incrementCurrentIndex(); event.accepted = true; }
        else if (event.key === Qt.Key_Left) { wallList.decrementCurrentIndex(); event.accepted = true; }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            selectAndClose();
            event.accepted = true;
        }
    }
}