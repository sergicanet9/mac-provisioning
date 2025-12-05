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
# App lists
# ===========================================
personal_apps=(
    "/System/Applications/Launchpad.app"
    "/Applications/Safari.app"
    "/System/Applications/Mail.app"
    "/System/Applications/Calendar.app"
    "/System/Applications/Notes.app"
    "/System/Applications/App Store.app"
    "/System/Applications/System Settings.app"
    "/Applications/iTerm.app"
    "/Applications/Visual Studio Code.app"
)

work_apps=(
    "/System/Applications/Launchpad.app"
    "/Applications/Microsoft Edge.app"
    "/Applications/Microsoft Outlook.app"
    "/Applications/Microsoft Teams.app"
    "/Applications/Notion.app"
    "/System/Applications/System Settings.app"
    "/Applications/iTerm.app"
    "/Applications/Visual Studio Code.app"
)

# ===========================================
# Menu
# ===========================================
echo "Choose Dock configuration:"
echo "1) Personal"
echo "2) Work"
echo "3) Skip"
read -rp "Enter choice [1-3]: " choice

defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock show-recents -bool false

case "$choice" in
    1) add_apps_to_dock "${personal_apps[@]}" ;;
    2) add_apps_to_dock "${work_apps[@]}" ;;
    3) echo "Skipping Dock configuration." ;;
    *) echo "Invalid choice. Skipping Dock configuration." ;;
esac

# ===========================================
# Restart Dock to apply changes
# ===========================================
killall Dock
echo "Dock configuration applied."
