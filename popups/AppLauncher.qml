import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: launcherRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    
    readonly property int itemHeight: 42
    readonly property int basePadding: 60
    readonly property int maxHeight: 550
    readonly property int preferredHeight: Math.min(maxHeight, (displayModel.count * itemHeight) + basePadding)

    ListModel { id: masterModel }
    ListModel { id: displayModel }

    Component.onCompleted: {
        if (shellRoot.bottomPanelMode === "launcher" && shellRoot.showBottomPanel) {
            triggerLauncher();
        }
    }

    function applyFilter(filterText) {
        displayModel.clear()
        const search = filterText.toLowerCase()
        for (let i = 0; i < masterModel.count; i++) {
            const item = masterModel.get(i)
            if (search === "" || item.name.toLowerCase().includes(search)) {
                displayModel.append(item)
            }
        }
        appList.currentIndex = 0
    }

    Process {
        id: appScanner
        command: [
            "bash", "-c", 
            "for d in /usr/share/applications/ ~/.local/share/applications/ /var/lib/flatpak/exports/share/applications/; do " +
            "  [ -d \"$d\" ] && for f in \"$d\"*.desktop; do " +
            "    [ -e \"$f\" ] || continue; " +
            "    grep -qi 'NoDisplay=true' \"$f\" && continue; " +
            "    name=$(grep -m 1 '^Name=' \"$f\" | cut -d'=' -f2-); " +
            "    exec=$(grep -m 1 '^Exec=' \"$f\" | cut -d'=' -f2- | sed 's/ %.*//'); " +
            "    icon=$(grep -m 1 '^Icon=' \"$f\" | cut -d'=' -f2-); " +
            "    if [ ! -z \"$name\" ] && [ ! -z \"$exec\" ]; then echo \"$name|$exec|$icon\"; fi; " +
            "  done; " +
            "done | sort -uf"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                masterModel.clear()
                const lines = this.text.trim().split("\n")
                for (let line of lines) {
                    if (line.trim() === "") continue;
                    const parts = line.split("|")
                    if (parts.length >= 3) {
                        masterModel.append({ "name": parts[0], "exec": parts[1], "iconName": parts[2] })
                    }
                }
                applyFilter(searchInput.text)
            }
        }
    }

    Connections {
        target: shellRoot
        function onShowBottomPanelChanged() {
            if (shellRoot.showBottomPanel && shellRoot.bottomPanelMode === "launcher") {
                triggerLauncher();
            } else {
                searchInput.text = "";
            }
        }
    }

    function triggerLauncher() {
        appScanner.running = false; 
        appScanner.running = true; 
        searchInput.forceActiveFocus();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 40; radius: 10; color: shellRoot.gray
            RowLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 8
                Text { text: "󰍉"; color: shellRoot.inactiveColor; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" }
                TextInput {
                    id: searchInput; Layout.fillWidth: true; color: shellRoot.textColor
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; focus: true
                    onTextChanged: applyFilter(text)
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Down) { appList.incrementCurrentIndex(); event.accepted = true }
                        else if (event.key === Qt.Key_Up) { appList.decrementCurrentIndex(); event.accepted = true }
                    }
                    onAccepted: {
                        if (displayModel.count > 0) {
                            const selectedApp = displayModel.get(appList.currentIndex)
                            Quickshell.execDetached(["bash", "-c", selectedApp.exec])
                            shellRoot.showBottomPanel = false
                        }
                    }
                    Text { text: "Search apps..."; color: shellRoot.inactiveColor; visible: !parent.text && !parent.activeFocus; font.pixelSize: 13 }
                }
            }
        }

        
        ListView {
            id: appList
            Layout.fillWidth: true; Layout.fillHeight: true
            spacing: 2; clip: true
            model: displayModel
            currentIndex: 0
            highlightMoveDuration: 150

            delegate: Item {
                width: appList.width; implicitHeight: 40
                readonly property bool isSelected: ListView.isCurrentItem

                Rectangle {
                    anchors.fill: parent; radius: 8
                    color: (mouseArea.containsMouse || isSelected) ? shellRoot.gray : "transparent"
                    border.width: isSelected ? 1 : 0
                    border.color: shellRoot.accentColor

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                        
                        Rectangle {
                            width: 28; implicitHeight: 28; radius: 6; color: shellRoot.darkerGray
                            
                            IconImage {
                                anchors.fill: parent; anchors.margins: 4
                                
                                
                                source: {
                                    if (!iconName) return "";
                                    if (iconName.startsWith("/")) return "file://" + iconName;
                                    return "file:///home/rezeke/.local/share/icons/Tela-grey/scalable/apps/" + iconName + ".svg";
                                }

                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        source = "image://icon/" + iconName;
                                    }
                                }
                            }
                        }

                        Text { 
                            text: name; color: isSelected ? shellRoot.activeColor : shellRoot.textColor
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; Layout.fillWidth: true 
                        }
                    }
                    MouseArea {
                        id: mouseArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: { 
                            appList.currentIndex = index
                            Quickshell.execDetached(["bash", "-c", exec])
                            shellRoot.showBottomPanel = false 
                        }
                    }
                }
            }
        }
    }
}