import QtQuick
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Io

import "."
import "../components/"
import "../widgets/"
import "../settings/"
import "../popups/"
import "../panels/"
import "../shell/"

PanelWindow {
    id: leftPanelWindow
    anchors { top: true; bottom: true; left: true }
    margins { top: 0; bottom: 0; left: shouldBeVisible ? 0 : -400 }
    color: "transparent"
    width: 400 + 20 

    focusable: true 
    
    readonly property bool shouldBeVisible: shellRoot.leftPanelActive
    exclusionMode: ExclusionMode.Normal

    onShouldBeVisibleChanged: {
        if (!shouldBeVisible && stackView.depth > 1) stackView.pop(null)
    }

    MouseArea {
        anchors.fill: parent; hoverEnabled: true; z: -1 
        onExited: { 
            shellRoot.toggleLeftPanel()
         }
    }

    Item {
        id: wrapper; anchors.fill: parent
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }

        BarCorner {
            anchors.top: parent.top; anchors.left: container.right 
            position: "top-left"; cornerRadius: 20; shapeColor: shellRoot.backgroundColor
        }

        BarCorner {
            anchors.bottom: parent.bottom; anchors.left: container.right
            position: "bottom-left"; cornerRadius: 20; shapeColor: shellRoot.backgroundColor
        }

        Rectangle {
            id: container
            width: 400; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
            color: shellRoot.backgroundColor

            StackView {
                id: stackView; anchors.fill: parent; initialItem: dashboardComponent; clip: true 
                pushEnter: Transition { NumberAnimation { properties: "x"; from: -400; to: 0; duration: 300; easing.type: Easing.OutCubic } }
                popExit: Transition { NumberAnimation { properties: "x"; from: 0; to: -400; duration: 300; easing.type: Easing.OutCubic } }
            }
        }
    }

    Component {
        id: dashboardComponent
        Item {
            id: dashboardItem
            anchors.fill: parent
            property string activeTab: "overview"
            
            
            Connections {
                target: leftPanelWindow
                function onShouldBeVisibleChanged() {
                    if (!leftPanelWindow.shouldBeVisible) {
                        activeTab = "overview"
                        searchText = ""
                    }
                }
            }

            
            property string searchText: ""
            property string sortRole: "cpu"
            property var rawCache: []
            ListModel { id: processModel }

            function applyFilterAndSort() {
                let filtered = rawCache.filter(item => 
                    searchText === "" || item.name.toLowerCase().includes(searchText.toLowerCase())
                );
                filtered.sort((a, b) => {
                    if (sortRole === "cpu") return b.cpu - a.cpu;
                    if (sortRole === "mem") return b.mem - a.mem;
                    if (sortRole === "name") return a.name.localeCompare(b.name);
                    if (sortRole === "pid") return parseInt(b.pid) - parseInt(a.pid);
                    return 0;
                });
                processModel.clear();
                for (let i = 0; i < filtered.length; i++) processModel.append(filtered[i]);
            }

            onSearchTextChanged: applyFilterAndSort()
            onSortRoleChanged: applyFilterAndSort()

            
            property string distroName: "Arch Linux"
            property string userHost: "user@host"
            property string qsVersion: "Quickshell"
            property string sessionType: "Wayland"
            property string uptimeStr: "..."
            property real cpuPercent: 0.0
            property string ramText: "0/0 MB"
            property real ramPercent: 0.0
            property string diskText: "0/0 GB"
            property real diskPercent: 0.0
            property string kernelStr: ""
            property string batteryStr: "0%"
            property string acStatus: "..."

            Process {
                id: getProcesses
                command: ["sh", "-c", "ps -eo pid,comm,%cpu,%mem --no-headers"]
                running: leftPanelWindow.shouldBeVisible && activeTab === "monitor"
                stdout: StdioCollector {
                    onTextChanged: {
                        let lines = text.trim().split('\n');
                        let temp = [];
                        for (let line of lines) {
                            let parts = line.trim().split(/\s+/);
                            if (parts.length < 4) continue;
                            temp.push({ "pid": parts[0], "name": parts[1], "cpu": parseFloat(parts[2]), "mem": parseFloat(parts[3]) });
                        }
                        rawCache = temp;
                        applyFilterAndSort();
                    }
                }
            }

            Process { id: killProcess }

            function killPid(pid, name) {
                shellRoot.confirmTitle = "Kill Process?";
                shellRoot.confirmMessage = "Are you sure you want to stop " + name + " (PID: " + pid + ")?";
                shellRoot.confirmCallback = function() {
                    killProcess.command = ["kill", "-9", pid];
                    killProcess.running = true;
                    getProcesses.running = true;
                };
                shellRoot.isConfirmDialogOpen = true;
            }

            Process {
                id: getStaticStats
                command: ["sh", "-c", "grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '\"'; echo \"$USER@$(hostname)\"; quickshell --version | head -n1; echo $XDG_SESSION_TYPE; uname -r"]
                running: leftPanelWindow.shouldBeVisible
                stdout: StdioCollector {
                    onTextChanged: {
                        let lines = text.trim().split('\n');
                        if (lines.length >= 1) distroName = lines[0];
                        if (lines.length >= 2) userHost = lines[1];
                        if (lines.length >= 3) qsVersion = lines[2];
                        if (lines.length >= 4) sessionType = lines[3];
                        if (lines.length >= 5) kernelStr = lines[4];
                    }
                }
            }

            Process {
                id: getDynamicStats
                command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'; free -m | awk '/Mem:/ {printf \"%d/%d MB|%.2f\\n\", $3, $2, $3/$2}'; df -h / --output=used,size,pcent | tail -1 | awk '{printf \"%s/%s|%.2f\\n\", $1, $2, substr($3, 1, length($3)-1)/100}'; uptime -p | sed 's/up //'; cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo 0; cat /sys/class/power_supply/AC*/online 2>/dev/null || echo 0"]
                running: leftPanelWindow.shouldBeVisible
                stdout: StdioCollector {
                    onTextChanged: {
                        let lines = text.trim().split('\n');
                        if (lines.length >= 1) cpuPercent = parseFloat(lines[0]) / 100;
                        if (lines.length >= 2) { let parts = lines[1].split('|'); ramText = parts[0]; ramPercent = parseFloat(parts[1]); }
                        if (lines.length >= 3) { let parts = lines[2].split('|'); diskText = parts[0]; diskPercent = parseFloat(parts[1]); }
                        if (lines.length >= 4) uptimeStr = lines[3];
                        if (lines.length >= 5) batteryStr = lines[4] + "%";
                        if (lines.length >= 6) acStatus = lines[5] === "1" ? "online" : "battery";
                    }
                }
            }

            Timer {
                interval: 5000; running: leftPanelWindow.shouldBeVisible; repeat: true
                onTriggered: getDynamicStats.running = true
            }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 25; spacing: 20

                RowLayout {
                    Layout.fillWidth: true; spacing: 0
                    Repeater {
                        model: ["Overview", "Monitor"]
                        delegate: ColumnLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text {
                                text: (modelData === "Overview" ? "󰕮 " : "󰚩 ") + modelData
                                color: activeTab === modelData.toLowerCase() ? shellRoot.textColor : shellRoot.inactiveColor
                                font.pixelSize: 14; font.bold: true; font.family: "JetBrainsMono Nerd Font"; Layout.alignment: Qt.AlignHCenter
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: activeTab = modelData.toLowerCase() }
                            }
                            Rectangle { 
                                Layout.fillWidth: true; implicitHeight: 2; 
                                color: activeTab === modelData.toLowerCase() ? shellRoot.textColor : "transparent"
                            }
                        }
                    }
                }

                StackLayout {
                    currentIndex: activeTab === "overview" ? 0 : 1
                    Layout.fillWidth: true; Layout.fillHeight: true

                    ScrollView {
                        id: overviewScroll; Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOff; contentWidth: overviewScroll.availableWidth
                        ColumnLayout {
                            width: overviewScroll.availableWidth; spacing: 15
                            RowLayout {
                                Layout.fillWidth: true; spacing: 12
                                Text { text: "󰣇"; color: shellRoot.textColor; font.pixelSize: 45 }
                                ColumnLayout {
                                    spacing: 0; Layout.fillWidth: true
                                    Text { text: distroName; color: shellRoot.textColor; font.pixelSize: 18; font.bold: true; font.family: "JetBrainsMono Nerd Font"; elide: Text.ElideRight; Layout.fillWidth: true }
                                    Text { text: userHost; color: shellRoot.inactiveColor; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                ColumnLayout {
                                    spacing: 0; Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    Text { text: qsVersion; color: shellRoot.inactiveColor; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight; Layout.maximumWidth: 100 }
                                    Text { text: sessionType.charAt(0).toUpperCase() + sessionType.slice(1).toLowerCase() + " vRC"; color: shellRoot.inactiveColor; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; horizontalAlignment: Text.AlignRight }
                                }
                            }
                            StatCard { label: "Uptime"; value: uptimeStr }
                            StatCard { label: "Operating System"; value: distroName.length > 20 ? distroName.substring(0, 17) + "..." : distroName }
                            Rectangle {
                                Layout.fillWidth: true; implicitHeight: 220; radius: 20; color: shellRoot.gray
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 20; spacing: 18
                                    UsageBar { label: "CPU Usage"; percent: cpuPercent; valueText: Math.round(cpuPercent * 100) + "%" }
                                    UsageBar { label: "Ram Usage"; percent: ramPercent; valueText: ramText }
                                    UsageBar { label: "Disk Usage"; percent: diskPercent; valueText: diskText }
                                }
                            }
                            RowLayout {
                                spacing: 10; Layout.fillWidth: true
                                StatCard { label: "Kernel"; value: kernelStr.length > 5 ? kernelStr.substring(0, 5) + "..." : kernelStr; implicitHeight: 65 }
                                StatCard { label: "Arch"; value: "x86_64"; implicitHeight: 65 }
                            }
                            RowLayout {
                                spacing: 10; Layout.fillWidth: true
                                StatCard { label: "Battery"; value: batteryStr; implicitHeight: 65 }
                                StatCard { label: "AC"; value: acStatus; implicitHeight: 65 }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true; spacing: 15
                        RowLayout {
                            Layout.fillWidth: true; spacing: 10
                            Rectangle {
                                Layout.fillWidth: true; implicitHeight: 45; radius: 12; color: shellRoot.gray
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 10
                                    Text { text: "󰍉"; color: shellRoot.inactiveColor; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font" }
                                    TextInput {
                                        id: searchInput; Layout.fillWidth: true; color: shellRoot.textColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                                        focus: true; onTextChanged: searchText = text
                                        Text { text: "Search process..."; color: shellRoot.inactiveColor; font.family: "JetBrainsMono Nerd Font"; visible: !parent.text && !parent.activeFocus; font.pixelSize: 13 }
                                    }
                                }
                            }
                            Rectangle {
                                width: 45; implicitHeight: 45; radius: 12; color: shellRoot.gray
                                Text { 
                                    text: "󰑐"; anchors.centerIn: parent; color: shellRoot.textColor; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"
                                    RotationAnimation on rotation { running: getProcesses.running; from: 0; to: 360; duration: 500; loops: Animation.Infinite }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: getProcesses.running = true }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Repeater {
                                model: ["CPU", "MEM", "NAME", "PID"]
                                delegate: Rectangle {
                                    Layout.fillWidth: true; implicitHeight: 30; radius: 8
                                    color: sortRole === modelData.toLowerCase() ? shellRoot.textColor : shellRoot.gray
                                    Text {
                                        anchors.centerIn: parent; text: modelData; font.pixelSize: 10; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                                        color: sortRole === modelData.toLowerCase() ? shellRoot.backgroundColor : shellRoot.textColor
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: sortRole = modelData.toLowerCase() }
                                }
                            }
                        }

                        ListView {
                            id: procList; Layout.fillWidth: true; Layout.fillHeight: true; model: processModel; clip: true; spacing: 8
                            delegate: Rectangle {
                                width: procList.width; implicitHeight: 55; radius: 12; color: shellRoot.gray
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 15
                                    ColumnLayout {
                                        spacing: 2; Layout.fillWidth: true
                                        Text { text: name; color: shellRoot.textColor; font.bold: true; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; elide: Text.ElideRight; Layout.fillWidth: true }
                                        Text { text: "PID: " + pid; color: shellRoot.textColor; opacity: 0.6; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font" }
                                    }
                                    Text { text: "󰻠 " + cpu + "%"; color: cpu > 50 ? "#ff5555" : shellRoot.textColor; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
                                    Text { text: "󰍛 " + mem + "%"; color: shellRoot.textColor; opacity: 0.8; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
                                    Rectangle {
                                        width: 28; implicitHeight: 28; radius: 14; color: "#222"
                                        Text { text: "󰅖"; anchors.centerIn: parent; color: "#ff5555"; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
                                        MouseArea { anchors.fill: parent; onClicked: killPid(pid, name) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Component.onCompleted: { getStaticStats.running = true; getDynamicStats.running = true; getProcesses.running = true; }
        }
    }
}