#!/bin/bash

SOURCE_DIR=$(pwd)
TARGET_DIR="$HOME/.config/quickshell"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

if [ -d "$TARGET_DIR" ]; then
    rm -rf "${TARGET_DIR}.bak" 2>/dev/null
    mv "$TARGET_DIR" "${TARGET_DIR}.bak" 2>/dev/null
fi

mkdir -p "$TARGET_DIR" 2>/dev/null

cp -rf "$SOURCE_DIR"/* "$TARGET_DIR/" 2>/dev/null

if [ -f "$HYPR_CONF" ]; then
    if ! grep -q "quickshell:toggle-bottom-panel" "$HYPR_CONF"; then
        cat <<EOF >> "$HYPR_CONF"

# --- shell-gw auto-generated binds ---
bind = SUPER, R, global, quickshell:toggle-bottom-panel
bind = SUPER, T, global, quickshell:toggle-wallpaper-changer
bind = SUPER, X, global, quickshell:toggle-clipboard
# -------------------------------------
EOF
    fi
fi