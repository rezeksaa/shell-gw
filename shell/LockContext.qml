import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Io

Scope {
    id: root
    signal unlocked()
    signal failed()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property string wallpaperPath: ""

    onCurrentTextChanged: showFailure = false;

    function tryUnlock() {
        if (currentText === "") return;
        root.unlockInProgress = true;
        pam.start();
    }
    
    function refreshWallpaper() {
        console.log("Refreshing wallpaper...")
        wallpaperQuery.running = true
    }
    
    
    onUnlocked: {
        unlockProcess.running = true
    }
    
    Process {
        id: unlockProcess
        command: ["loginctl", "unlock-session"]
        running: false
    }

    
    Process {
        id: wallpaperQuery
        command: ["sh", "-c", "swww query | awk -F'image: ' '{print $2}' | head -1"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("=== Wallpaper Query ===")
                console.log("Raw output:", text)
                
                if (text && text.trim() !== "") {
                    let path = text.trim()
                    if (path.startsWith("/")) {
                        console.log("✓ Wallpaper path set to:", path)
                        root.wallpaperPath = path
                        return
                    }
                }
                
                console.log("✗ swww query returned empty or invalid path, trying fallback...")
                fallbackQuery.running = true
            }
        }
        
        onExited: (code, status) => {
            if (code !== 0) {
                console.log("swww query failed with code:", code)
                fallbackQuery.running = true
            }
        }
    }
    
    
    Process {
        id: fallbackQuery
        command: ["sh", "-c", "find ~/Pictures/Wallpapers ~/wallpapers ~/.config/wallpapers -maxdepth 2 -type f \\( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' -o -name '*.webp' \\) 2>/dev/null | head -1"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "") {
                    let path = text.trim()
                    console.log("✓ Fallback wallpaper found:", path)
                    root.wallpaperPath = path
                } else {
                    console.log("✗ No wallpaper found, using solid color")
                    root.wallpaperPath = ""
                }
            }
        }
    }

    PamContext {
        id: pam
        configDirectory: "pam"
        config: "password.conf"

        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText);
            }
        }

        onCompleted: result => {
            if (result == PamResult.Success) {
                root.unlocked();
            } else {
                root.currentText = "";
                root.showFailure = true;
            }
            root.unlockInProgress = false;
        }
    }
}