import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications

import "."
import "./components/"
import "./widgets/"
import "./settings/"
import "./popups/"
import "./panels/"
import "./shell/"

ShellRoot { 
    id: shellRoot
    objectName: "shellRoot"
  
    property color borderColor: "#E0E0E0"
    property color backgroundColor: "#141211"
    property color activeColor: "white"
    property color inactiveColor: "#666666"
    property color accentColor: "#D2D2B4"
    property color textColor: "#C6C8B0"
    property color gray: "#2A2A2A"
    property color darkerGray: "#1c1c1a"
    property real globalRadius: 20

    property bool isSilent: false
    property bool showWidgets: false 
    property bool activeLeftPanel: false
    property bool clipboardActive: false
    property bool powerMenuActive: false
    property bool showBottomPanel: false    
    property bool bottomPanelActive: false  
    property string bottomPanelMode: "launcher"
    property bool showActivePanel: false    
    property bool activePanelActive: false  
    property bool leftPanelActive: false  
    property bool isConfirmDialogOpen: false
    property string confirmTitle: ""
    property string confirmMessage: ""
    property var confirmCallback: null
    property bool lockScreenActive: false
    property bool settingActive: false

    readonly property bool anyPanelOpen: showWidgets || showBottomPanel || showActivePanel || leftPanelActive || clipboardActive || powerMenuActive

    ListModel { id: globalNotificationModel }

    
    NotificationServer {
        id: globalNotificationServer
        onNotification: (n) => {
            
            globalNotificationModel.insert(0, {
                "summary": n.summary || "No Summary",
                "body": n.body || "",
                "appName": n.appName || "System",
                "time": Qt.formatDateTime(new Date(), "hh:mm")
            })
            
            
            if (!shellRoot.isSilent) {
                notificationOSD.summary = n.summary
                notificationOSD.body = n.body
                notificationOSD.isShown = true
                notificationOSD.restartTimer() 
            }
        }
    }

    
    Timer { id: openingTimer; interval: 50; onTriggered: shellRoot.showBottomPanel = true }
    Timer { id: closingTimer; interval: 550; onTriggered: shellRoot.bottomPanelActive = false }
    Timer { id: openingTimerSide; interval: 50; onTriggered: shellRoot.showActivePanel = true }
    Timer { id: closingTimerSide; interval: 450; onTriggered: shellRoot.activePanelActive = false }
    Timer { id: openingTimerLeft; interval: 50; onTriggered: shellRoot.leftPanelActive = true }
    Timer { id: closingTimerLeft; interval: 450; onTriggered: shellRoot.activeLeftPanel = false }

    
    LockContext {
        id: lockContext
        onUnlocked: {
            
            if (lockScreenLoader.item) {
                lockScreenLoader.item.locked = false
            }
            
            
            unlockTimer.start()
        }
    }
    
    
    Timer {
        id: unlockTimer
        interval: 100  
        onTriggered: {
            
            shellRoot.lockScreenActive = false
            
            
            lockContext.currentText = ""
            lockContext.showFailure = false
            lockContext.unlockInProgress = false
        }
    }

    
    Loader {
        id: lockScreenLoader
        active: shellRoot.lockScreenActive
        sourceComponent: lockScreenComponent
        
        onLoaded: {
            
            lockContext.refreshWallpaper()
        }
    }

    Loader {
        id: settingsLoader
        source: "./settings/Settings.qml"
        active: settingActive
    }

    Component {
        id: lockScreenComponent
        
        WlSessionLock {
            locked: true
            
            WlSessionLockSurface {
                LockSurface {
                    anchors.fill: parent
                    context: lockContext
                }
            }
        }
    }

    function activateLockScreen() {
        if (!lockScreenActive) {
            lockScreenActive = true
        }
    }

    function closeAllPanels() {
        showWidgets = false;
        if (showBottomPanel) { showBottomPanel = false; closingTimer.start(); }
        if (showActivePanel) { showActivePanel = false; closingTimerSide.start(); }
        if (leftPanelActive) { leftPanelActive = false; closingTimerLeft.start(); }
        clipboardActive = false;
        powerMenuActive = false;
    }

    
    function toggleWidgets() { if (showWidgets) showWidgets = false; else { closeAllPanels(); showWidgets = true; } }
    function togglePanel() { if (showActivePanel) { showActivePanel = false; closingTimerSide.start(); } else { closeAllPanels(); activePanelActive = true; openingTimerSide.start(); } }
    function togglePowerMenu() { if (powerMenuActive) powerMenuActive = false; else { closeAllPanels(); powerMenuActive = true; } }
    function toggleSetting() { if (settingActive) settingActive = false; else { closeAllPanels(); settingActive = true; } }
    function toggleLeftPanel() { if (leftPanelActive) { leftPanelActive = false; closingTimerLeft.start(); } else { closeAllPanels(); activeLeftPanel = true; openingTimerLeft.start(); } }
    function toggleClipboard() { if (clipboardActive) clipboardActive = false; else { closeAllPanels(); clipboardActive = true; } }
    function toggleBottomPanelLauncher() { if (showBottomPanel && bottomPanelMode === "launcher") { showBottomPanel = false; closingTimer.start(); } else { closeAllPanels(); bottomPanelMode = "launcher"; bottomPanelActive = true; openingTimer.start(); } }
    function toggleBottomPanelWallpaper() { if (showBottomPanel && bottomPanelMode === "wallpaper") { showBottomPanel = false; closingTimer.start(); } else { closeAllPanels(); bottomPanelMode = "wallpaper"; bottomPanelActive = true; openingTimer.start(); } }
    function toggleLockScreen() { 
        if (!lockScreenActive) {
            activateLockScreen()
        }
    }
    
    GlobalShortcut { name: "toggle-bottom-panel"; onPressed: toggleBottomPanelLauncher() }
    GlobalShortcut { name: "toggle-wallpaper-changer"; onPressed: toggleBottomPanelWallpaper() }
    GlobalShortcut { name: "toggle-right-panel"; onPressed: togglePanel() }
    GlobalShortcut { name: "toggle-clipboard"; onPressed: toggleClipboard() }
    GlobalShortcut { 
        name: "lock-screen"; 
        onPressed: toggleLockScreen()
    }

    Process {
        id: logindMonitor
        command: ["dbus-monitor", "--system", "type='signal',interface='org.freedesktop.login1.Session',member='Lock"]
        running: true
        
        stdout: SplitParser {
            onRead: data => {
                if (data.includes("Lock") && !shellRoot.lockScreenActive) {
                    shellRoot.activateLockScreen()
                }
            }
        }
    }

    TopPanel { id: musicLoader } 
    NotificationPopup { id: notificationOSD }

    ConfirmationDialog {
        title: shellRoot.confirmTitle
        message: shellRoot.confirmMessage
        onAccept: shellRoot.confirmCallback
    }

    Loader { active: activePanelActive; source: "./panels/RightPanel.qml" }
    Loader { active: powerMenuActive; source: "./popups/PowerMenu.qml" }
    Loader { active: activeLeftPanel; source: "./panels/LeftPanel.qml" }
    Loader { active: clipboardActive; source: "./settings/ClipboardContent.qml" }
    Loader { active: bottomPanelActive; source: "./panels/BottomPanel.qml" }

    TopBar { } 
    Corner { id: corner }
}