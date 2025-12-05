#!/usr/bin/env bash
# ==================================================
# dock.sh - Configure macOS Dock
# ==================================================

# ===========================================
# Functions
# ===========================================
add_app() {
    local APP_PATH="$1"
    defaults write com.apple.dock persistent-apps -array-add \
    "<dict>
        <key>tile-data</key>
        <dict>
            <key>file-data</key>
            <dict>
                <key>_CFURLString</key>
                <string>$APP_PATH</string>
                <key>_CFURLStringType</key>
                <integer>0</integer>
            </dict>
        </dict>
        <key>tile-type</key>
        <string>file-tile</string>
    </dict>"
}

add_apps_to_dock() {
    local apps=("$@")
    for app in "${apps[@]}"; do
        APP_PATH=$(readlink -f "$app")
        add_app "$APP_PATH"
    done
}

# ===========================================
# Apply dock
# ===========================================
if [ $# -eq 0 ]; then
    echo "No dock apps provided. Skipping."
    exit 0
fi

defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock show-recents -bool false

add_apps_to_dock "$@"