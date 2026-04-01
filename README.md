# shell-gw
Desktop shell built with Quickshell and QML, featuring integrated MPRIS media control, system settings, and a modular widget system.

---

### 📺 Demo
<div align="center">
  <video src="assets/demo.mp4" width="100%" controls muted></video>
</div>

---

### Features
* **Dynamic Music Center**: Full MPRIS integration (optimized for Spotify) with live progress tracking, album art caching, and clickable seeking.
* **Hardware Management**: Custom-built modules for WiFi (NetworkManager), Bluetooth (BlueZ), and system brightness/volume control.
* **Modern Aesthetics**: Custom "BarCorner" components for seamless UI transitions and a consistent global radius across all panels.

not as good as the other shell, but i made it myseft ;)

# Keybindings 
These binds communicate with Quickshell's GlobalShortcut service

```
bind = SUPER, R, global, quickshell:toggle-bottom-panel
bind = SUPER, T, global, quickshell:toggle-wallpaper-changer
bind = SUPER, X, global, quickshell:toggle-clipboard
```

### Installation
I'm not even gonna bother with a complex installation process. Just run the script.

```
git clone [https://github.com/rezeksaa/shell-gw.git](https://github.com/rezeksaa/shell-gw.git)
cd shell-gw
chmod +x install.sh
./install.sh
quickshell
```

if it break then it's a feature
