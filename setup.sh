#!/usr/bin/env bash
# ==================================================
# mac-provisioning - setup.sh
# Installs or updates mac-provisioning on a Mac.
# ==================================================

# ===========================================
# Variables & Functions
# ===========================================
FILES_BASE="https://raw.githubusercontent.com/sergicanet9/mac-provisioning/main"
LATEST_VERSION=$(curl -fsSL -H "Cache-Control: no-cache" "$FILES_BASE/VERSION")
if [ -z "$LATEST_VERSION" ]; then
    echo "Could not fetch VERSION from $FILES_BASE/VERSION"
    exit 1
fi

INSTALL_DIR="$HOME/.mac-provisioning"
BACKUP_DIR="$INSTALL_DIR/backup"
VERSION_FILE="$INSTALL_DIR/version"
PROFILE_FILE=$INSTALL_DIR/profile

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

PROFILES=("personal" "work")
declare profile

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Backup existing $(basename "$file")"
        cp "$file" "$BACKUP_DIR/Backup_$(basename "$file")_$TIMESTAMP"
    fi
}

install_file() {
    local filename="$1"
    local target="$2"

    backup_file "$target"

    echo "Installing $filename"
    curl -fsSL "$FILES_BASE/$filename" -o "$target"
}

# ===========================================
echo "1. Check mac-provisioning install"
# ===========================================
new_install=false
if [ ! -d "$INSTALL_DIR" ]; then
    new_install=true
    echo "mac-provisioning not found. Installing from scratch..."
else
    if [ ! -f "$VERSION_FILE" ] || [ ! -f "$PROFILE_FILE" ] || [ ! -d "$BACKUP_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        new_install=true
        echo "Previous mac-provisioning installation is incomplete or corrupted. Reinstalling from scratch..."
    else
        profile=$(cat "$PROFILE_FILE")
        if [[ ! " ${PROFILES[*]} " =~ " ${profile} " ]]; then
            rm -rf "$INSTALL_DIR"
            new_install=true
            echo "Invalid profile detected in $PROFILE_FILE: $profile. Reinstalling from scratch..."
        else
            echo "mac-provisioning installation found with profile: $profile"

            installed_version=$(cat "$VERSION_FILE")
            if [ "$installed_version" = "$LATEST_VERSION" ]; then
                echo "mac-provisioning is already up to date at version: $installed_version. Reinstalling..."
            else
                echo "mac-provisioning $installed_version has been found. Updating to version $LATEST_VERSION..."
            fi
        fi
    fi
fi

if [ "$new_install" = true ]; then
    mkdir -p "$INSTALL_DIR" "$BACKUP_DIR"

    echo "Select a profile for this Mac:"
    select prof in personal work; do
        if [[ -n "$prof" ]]; then
            profile="$prof"
            echo "Profile set to $profile"
            echo "$profile" > "$PROFILE_FILE"
            break
        else
            echo "Invalid choice. Choose 1 or 2."
        fi
    done
fi

# # ===========================================
# echo "2. Install or update Xcode Command Line Tools"
# # ===========================================
# if ! xcode-select -p &>/dev/null; then
#     echo "Xcode Command Line Tools not found. Installing..."
#     xcode-select --install
# else
#     echo "Xcode Command Line Tools found. Checking for updates..."
#     softwareupdate --list 2>/dev/null | grep "Command Line Tools" && \
#         echo "Update available. Installing..." && \
#         softwareupdate --install -a --verbose
# fi

# # ===========================================
# echo "3. Install or update Oh My Zsh"
# # ===========================================
# OMZ_DIR="$HOME/.oh-my-zsh"
# if [ ! -d "$OMZ_DIR" ]; then
#     echo "Oh My Zsh not found. Installing..."
#     RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# else
#     echo "Oh My Zsh already installed. Updating..."
#     bash -c "$OMZ_DIR/tools/upgrade.sh"
# fi

# # ===========================================
# echo "4. Install or update Homebrew"
# # ===========================================
# if ! command -v brew &> /dev/null; then
#     echo "Homebrew not found. Installing..."
#     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# else
#     echo "Homebrew already installed. Updating..."
#     brew update
# fi

# # ===========================================
# echo "5. Apply Brewfile for packages and casks"
# # ===========================================
# BREWFILE_TMP="/tmp/Brewfile"

# curl -fsSL $FILES_BASE/homebrew/Brewfile -o "$BREWFILE_TMP"

# if [ ! -s "$BREWFILE_TMP" ]; then
#     echo "Failed to download Brewfile"
#     exit 1
# fi

# echo "Backing up Brewfile for packages and casks..."
# brew bundle dump --describe --force --no-vscode --file="$BACKUP_DIR/Backup_Brewfile_$TIMESTAMP"

# brew bundle install --file="$BREWFILE_TMP"

# # ===========================================
# echo "6. Apply Brewfile for Go packages"
# # ===========================================
# BREWFILE_TMP_GO="/tmp/Brewfile_go"

# curl -fsSL $FILES_BASE/go/Brewfile -o "$BREWFILE_TMP_GO"

# if [ ! -s "$BREWFILE_TMP_GO" ]; then
#     echo "Failed to download Brewfile"
#     exit 1
# fi

# echo "Backing up Brewfile for Go packages ..."
# brew bundle dump --describe --force --go --file="$BACKUP_DIR/Backup_Brewfile_go_$TIMESTAMP"

# brew bundle install --file="$BREWFILE_TMP_GO"

# # ===========================================
# echo "7. Configure git and clone repos"
# # ===========================================
# if ! git config --global --get user.name >/dev/null; then
#     read -rp "Enter your Git user name: " GIT_USER_NAME
#     git config --global user.name "$GIT_USER_NAME"
# else
#     GIT_USER_NAME=$(git config --global user.name)
#     echo "Git user name already set: $GIT_USER_NAME"
# fi

# if ! git config --global --get user.email >/dev/null; then
#     read -rp "Enter your Git user email: " GIT_USER_EMAIL
#     git config --global user.email "$GIT_USER_EMAIL"
# else
#     GIT_USER_EMAIL=$(git config --global user.email)
#     echo "Git user email already set: $GIT_USER_EMAIL"
# fi

# git config --global ghq.root "$HOME/Git"

# if ! gh auth status >/dev/null 2>&1; then
#     echo "Authenticate GitHub in your browser using HTTPS. The script will continue once login is complete:"
#     gh auth login
# else
#     echo "GitHub already authenticated — skipping login."
# fi

# GITHUB_USER=$(gh api user --jq .login)
# echo "Authenticated as: $GITHUB_USER"

# echo "Fetching all GitHub repos..."
# for repo in $(gh repo list "$GITHUB_USER" --limit 200 --json name,url -q '.[].url'); do
#     ghq get "$repo" || echo "Already cloned or failed: $repo"
# done

# # ===========================================
# echo "7. Install dotfiles"
# # ===========================================
# install_file "dotfiles/.zshrc" "$HOME/.zshrc"

# if [ ! -f "$HOME/.zshcustom" ]; then
#     install_file "dotfiles/.zshcustom" "$HOME/.zshcustom"
# fi

# # TODO separate profiles for work/personal
# # TODO readme

# ===========================================
echo "8. Set up macOS"
# ===========================================
echo "Show all filename extensions in Finder"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "Set Finder new window to Home folder"
defaults write com.apple.finder NewWindowTarget -string "PfHm"

echo "Show seconds in menu bar clock"
defaults write com.apple.menuextra.clock ShowSeconds -bool true

echo "Set Click wallpaper to reveal desktop off"
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

echo "Configure Dock"
bash -c "$(curl -fsSL $FILES_BASE/macos/dock.sh)"

killall Dock
killall Finder
killall WindowManager

echo "Install Safari extensions"
bash -c "$(curl -fsSL $FILES_BASE/macos/extensions.sh)"


# ===========================================
echo "9. Set installed version"
# ===========================================
echo "$LATEST_VERSION" > "$VERSION_FILE"
echo "$profile" > "$PROFILE_FILE"
echo "✅ mac-provisioning $LATEST_VERSION installed"