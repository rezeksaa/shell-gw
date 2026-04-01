# shell-gw
Desktop shell built with Quickshell and QML, featuring integrated MPRIS media control, system settings, and a modular widget system.

---

### 📺 Demo
<p align="center">
  <video src="https://github.com/user-attachments/assets/45c1233e-a54e-405f-9e95-de3985ea9b9b" width="100%" controls>
  </video>
</p>

---

### Features
* **Music Center**: Full MPRIS integration (optimized for Spotify).
* **Hardware Management**: Custom-built modules for WiFi, Bluetooth, and system brightness/volume control.

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
git clone https://github.com/rezeksaa/shell-gw.git
cd shell-gw
./install.sh
quickshell &; disown
```

if it break then it's a feature
