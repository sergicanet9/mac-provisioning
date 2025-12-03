#!/usr/bin/env bash
# ==================================================
# mac-provisioning - setup.sh
# Installs or updates mac-provisioning on a Mac.
# ==================================================

# ===========================================
# Constants & Helper functions
# ===========================================
FILES_BASE="https://raw.githubusercontent.com/sergicanet9/mac-provisioning/main"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
INSTALL_DIR="$HOME/.mac-provisioning"
BACKUP_DIR="$INSTALL_DIR/backup"

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Backup existing $(basename "$file")"
        mv "$file" "$BACKUP_DIR/$(basename "$file").backup_$TIMESTAMP"
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
echo "1. Check mac-provisioning installation"
# ===========================================
VERSION_FILE="$INSTALL_DIR/version"
VERSION_URL="$FILES_BASE/VERSION"

LATEST_VERSION=$(curl -sL -H "Cache-Control: no-cache" "$VERSION_URL")
if [ -z "$LATEST_VERSION" ]; then
    echo "Could not fetch VERSION from $VERSION_URL"
    exit 1
fi

if [ ! -f "$VERSION_FILE" ]; then
    echo "mac-provisioning not found. Installing..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BACKUP_DIR"
else
    INSTALLED_VERSION=$(cat "$VERSION_FILE")

    if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
        echo "✅ mac-provisioning is already up to date. Current version: $INSTALLED_VERSION"
        exit 0
    else
        echo "mac-provisioning $INSTALLED_VERSION already installed. Updating to $LATEST_VERSION..."
    fi
fi

# ===========================================
echo "2. Install or update Xcode Command Line Tools"
# ===========================================
if ! xcode-select -p &>/dev/null; then
    echo "Xcode Command Line Tools not found. Installing..."
    xcode-select --install
else
    echo "Xcode Command Line Tools found. Checking for updates..."
    softwareupdate --list 2>/dev/null | grep "Command Line Tools" && \
        echo "Update available. Installing..." && \
        softwareupdate --install -a --verbose
fi

# ===========================================
echo "3. Install or update Oh My Zsh"
# ===========================================
OMZ_DIR="$HOME/.oh-my-zsh"
if [ ! -d "$OMZ_DIR" ]; then
    echo "Oh My Zsh not found. Installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh already installed. Updating..."
    bash -c "$OMZ_DIR/tools/upgrade.sh"
fi

# ===========================================
echo "4. Install or update Homebrew"
# ===========================================
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" #TODO PREPEND NONINTERACTIVE=1?
else
    echo "Homebrew already installed. Updating..."
    brew update
fi

# ===========================================
echo "5. Apply Brewfile for packages and casks"
# ===========================================
BREWFILE_TMP="/tmp/Brewfile"

curl -sL $FILES_BASE/homebrew/Brewfile -o "$BREWFILE_TMP"

if [ ! -s "$BREWFILE_TMP" ]; then
    echo "Failed to download Brewfile"
    exit 1
fi

echo "Backing up Brewfile for packages and casks..."
brew bundle dump --describe --force --no-vscode --file="$BACKUP_DIR/.Brewfile_backup_$TIMESTAMP"

brew bundle install --file="$BREWFILE_TMP"

# ===========================================
echo "6. Apply Brewfile for Go packages"
# ===========================================
BREWFILE_TMP_GO="/tmp/Brewfile_go"

curl -sL $FILES_BASE/go/Brewfile -o "$BREWFILE_TMP_GO"

if [ ! -s "$BREWFILE_TMP_GO" ]; then
    echo "Failed to download Brewfile"
    exit 1
fi

echo "Backing up Brewfile for Go packages ..."
brew bundle dump --describe --force --go --file="$BACKUP_DIR/.Brewfile_go_backup_$TIMESTAMP"

brew bundle install --file="$BREWFILE_TMP_GO"

# ===========================================
echo "7. Configure git and clone repos"
# ===========================================
read -rp "Enter your Git user name: " GIT_USER_NAME
git config --global user.name "$GIT_USER_NAME"

read -rp "Enter your Git user email: " GIT_USER_EMAIL
git config --global user.email "$GIT_USER_EMAIL"

git config --global ghq.root "$HOME/Git"

if ! gh auth status >/dev/null 2>&1; then
    echo "Authenticate GitHub in your browser using HTTPS. The script will continue once login is complete:"
    gh auth login
else
    echo "GitHub already authenticated — skipping login."
fi

GITHUB_USER=$(gh api user --jq .login)
echo "Authenticated as: $GITHUB_USER"

echo "Fetching all GitHub repos..."
for repo in $(gh repo list "$GITHUB_USER" --limit 200 --json name,url -q '.[].url'); do
    ghq get "$repo" || echo "Already cloned or failed: $repo"
done

# ===========================================
echo "7. Install dotfiles"
# ===========================================
install_file "dotfiles/.zshrc" "$HOME/.zshrc"

if [ ! -f "$HOME/.zshcustom" ]; then
    install_file "dotfiles/.zshcustom" "$HOME/.zshcustom"
fi

# TODO mac settings, sidebar, finder setups
# TODO mac app store apps
# TODO vscode login?
# TODO backup only working for plists
# ===========================================
echo "8. Set up macOS"
# ===========================================
defaults write com.apple.menuextra.clock ShowSeconds -bool true
install_file "macos/com.apple.dock.plist" "$HOME/Library/Preferences/com.apple.dock.plist"
install_file "macos/com.apple.finder.plist" "$HOME/Library/Preferences/com.apple.finder.plist"
killall Dock
killall Finder

# ===========================================
echo "9. Set installed version"
# ===========================================
echo "$LATEST_VERSION" > "$VERSION_FILE"
echo "✅ mac-provisioning $LATEST_VERSION installed"