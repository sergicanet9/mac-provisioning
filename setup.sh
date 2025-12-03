#!/usr/bin/env bash
# ==================================================
# mac-provisioning - setup.sh
# Installs or updates mac-provisioning on a Mac.
# ==================================================

# ===========================================
# 1. Check if mac-provisioning is installed
# ===========================================
VERSION_FILE="$HOME/.mac_provisioning_version"
VERSION_URL="https://raw.githubusercontent.com/sergicanet9/mac-provisioning/main/VERSION"

LATEST_VERSION=$(curl -sL -H "Cache-Control: no-cache" "$VERSION_URL")
if [ -z "$LATEST_VERSION" ]; then
    echo "Could not fetch VERSION from $VERSION_URL"
    exit 1
fi

if [ ! -f "$VERSION_FILE" ]; then
    echo "mac-provisioning not found. Installing..."
    NEW_INSTALLATION=true
else
    INSTALLED_VERSION=$(cat "$VERSION_FILE")

    if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
        echo "✅ mac-provisioning is already up to date. Current version: $INSTALLED_VERSION"
        exit 0
    else
        echo "mac-provisioning $INSTALLED_VERSION already installed. Updating to $LATEST_VERSION..."
        NEW_INSTALLATION=false
    fi
fi

# ===========================================
# 2. Install dotfiles
# ===========================================
timestamp=$(date +"%Y%m%d_%H%M%S")
FILES_BASE="https://raw.githubusercontent.com/sergicanet9/mac-provisioning/main/dotfiles"

backup_file() {
    local file="$1"
    if [ -f "$file" ] && [ "$NEW_INSTALLATION" = false ]; then
        echo "Backup existing $(basename "$file")"
        mv "$file" "${file}.backup_$timestamp"
    fi
}

install_dotfile() {
    local filename="$1"
    local target="$HOME/$filename"

    backup_file "$target"

    echo "Installing $filename"
    curl -fsSL "$FILES_BASE/$filename" -o "$target"
}

install_dotfile ".zshrc"
install_dotfile ".zshcustom"
install_dotfile ".gitignore_global"
install_dotfile ".gitconfig"

echo "Dotfiles installed"

# ===========================================
# 3. Install or update Oh My Zsh
# ===========================================
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh not found. Installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh already installed. Updating..."
    omz update
fi

# ===========================================
# 4. Install or update Homebrew
# ===========================================
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew already installed. Updating..."
    brew update
fi

# TODO backup/dump current brew and go if new_installation=false?

# ===========================================
# 5. Apply Brewfile for packages and casks
# ===========================================
BREWFILE_TMP="/tmp/Brewfile"

curl -sL https://raw.githubusercontent.com/sergicanet9/mac-provisioning/main/homebrew/Brewfile -o "$BREWFILE_TMP"

if [ ! -s "$BREWFILE_TMP" ]; then
    echo "Failed to download Brewfile"
    exit 1
fi

brew bundle install --file="$BREWFILE_TMP"

# TODO donwload all github repos. PAT?
# TODO mac settings and dock, finder setups
# TODO vscode login?

# ===========================================
# 6. Apply Brewfile for Go packages
# ===========================================
BREWFILE_TMP_GO="/tmp/Brewfile/go"

curl -sL https://raw.githubusercontent.com/sergicanet9/mac-provisioning/main/go/Brewfile -o "$BREWFILE_TMP_GO"

if [ ! -s "$BREWFILE_TMP_GO" ]; then
    echo "Failed to download Brewfile"
    exit 1
fi

brew bundle install --file="$BREWFILE_TMP_GO"

# ===========================================
# 7. Set installed version
# ===========================================
echo "$LATEST_VERSION" > "$VERSION_FILE"
echo "✅ mac-provisioning $LATEST_VERSION installed"