import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Wayland
import QtQuick.Layouts

PanelWindow {
    id: clipPanel
    
    width: 400
    implicitHeight: 400
    
    focusable: true
    aboveWindows: true
    
    color: "transparent"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive 

    
    property int currentPage: 0
    property int itemsPerPage: 5
    property int totalPages: Math.ceil(searchModel.count / itemsPerPage)

    Rectangle {
        anchors.fill: parent
        color: shellRoot.backgroundColor
        radius: shellRoot.globalRadius
        border.width: 1
        border.color: shellRoot.gray

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Rectangle {
                id: searchBar
                Layout.fillWidth: true
                implicitHeight: 45
                radius: 10
                color: shellRoot.gray

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    Text { text: "󰍉"; color: shellRoot.accentColor; font.pixelSize: 18 }
                    TextInput {
                        id: clipSearch
                        Layout.fillWidth: true
                        color: shellRoot.textColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        focus: true
                        onTextChanged: { currentPage = 0; filterModel(); }
                        
                        Text { 
                            text: "Search clipboard..."
                            color: shellRoot.inactiveColor
                            visible: !parent.text && !parent.activeFocus
                            font.pixelSize: 14
                        }

                        Keys.onPressed: (event) => {
                            let oldIndex = clipList.currentIndex;

                            if (event.key === Qt.Key_Down) { 
                                if (clipList.currentIndex < clipList.count - 1) {
                                    clipList.incrementCurrentIndex();
                                } else if ((currentPage + 1) < totalPages) {
                                    currentPage++;
                                    updatePagedModel(0); 
                                }
                                event.accepted = true 
                            }
                            
                            if (event.key === Qt.Key_Up) { 
                                if (clipList.currentIndex > 0) {
                                    clipList.decrementCurrentIndex();
                                } else if (currentPage > 0) {
                                    currentPage--;
                                    updatePagedModel(itemsPerPage - 1); 
                                }
                                event.accepted = true 
                            }

                            if (event.key === Qt.Key_Right) {
                                if ((currentPage + 1) < totalPages) {
                                    currentPage++;
                                    updatePagedModel(oldIndex); 
                                }
                                event.accepted = true
                            }

                            if (event.key === Qt.Key_Left) {
                                if (currentPage > 0) {
                                    currentPage--;
                                    updatePagedModel(oldIndex);
                                }
                                event.accepted = true
                            }

                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { 
                                if (displayModel.count > 0) {
                                    let item = displayModel.get(clipList.currentIndex);
                                    selectItem(item.rawLine); 
                                }
                                event.accepted = true 
                            }
                            
                            if (event.key === Qt.Key_Escape) {
                                shellRoot.clipboardActive = false;
                                event.accepted = true;
                            }
                        }
                    }
                }
            }

            ListView {
                id: clipList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: displayModel
                spacing: 5
                clip: true
                currentIndex: 0
                interactive: false 

                delegate: Item {
                    width: clipList.width
                    implicitHeight: 50 
                    readonly property bool isSelected: ListView.isCurrentItem

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: isSelected ? shellRoot.gray : "transparent"
                        border.width: isSelected ? 1 : 0
                        border.color: shellRoot.accentColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            Text {
                                text: contentText
                                color: isSelected ? shellRoot.activeColor : shellRoot.textColor
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                clipList.currentIndex = index
                                selectItem(rawLine)
                            }
                        }
                    }
                }
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Page " + (currentPage + 1) + " of " + Math.max(1, totalPages)
                color: shellRoot.inactiveColor
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
            }
        }
    }

    ListModel { id: masterModel }
    ListModel { id: searchModel } 
    ListModel { id: displayModel }

    Process {
        id: clipScanner
        command: ["bash", "-c", "cliphist list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                masterModel.clear();
                let lines = text.trim().split("\n");
                for (let line of lines) {
                    if (line.trim() === "") continue;
                    let parts = line.split("\t");
                    masterModel.append({ 
                        "rawLine": line, 
                        "contentText": parts.length > 1 ? parts[1] : line 
                    });
                }
                filterModel();
            }
        }
    }

    function filterModel() {
        searchModel.clear();
        let search = clipSearch.text.toLowerCase();
        for (let i = 0; i < masterModel.count; i++) {
            let item = masterModel.get(i);
            if (search === "" || item.contentText.toLowerCase().includes(search)) {
                searchModel.append(item);
            }
        }
        updatePagedModel(0);
    }

    function updatePagedModel(targetIndex) {
        displayModel.clear();
        let start = currentPage * itemsPerPage;
        let end = Math.min(start + itemsPerPage, searchModel.count);
        
        for (let i = start; i < end; i++) {
            displayModel.append(searchModel.get(i));
        }

        let safeIndex = Math.min(targetIndex, displayModel.count - 1);
        clipList.currentIndex = Math.max(0, safeIndex);
    }

    
    function selectItem(rawLine) {
        Quickshell.execDetached([
            "bash", "-c", 
            "content=$(printf '%s' \"$1\" | cliphist decode); " +
            "echo -n \"$content\" | wl-copy; " +
            "notify-send -t 2000 -i 'edit-copy' 'Clipboard' \"Copied: ${content:0:60}...\"",
            "--", rawLine
        ]);
        
        shellRoot.clipboardActive = false; 
    }

    onVisibleChanged: if (visible) clipScanner.running = true
}