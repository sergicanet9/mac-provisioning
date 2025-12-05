#!/usr/bin/env bash
# ==================================================
# mac-provisioning - setup.sh
# Installs or updates mac-provisioning on a Mac.
# ==================================================

# ===========================================
# Variables
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
omz_dir="$HOME/.oh-my-zsh"
if [ ! -d "$omz_dir" ]; then
    echo "Oh My Zsh not found. Installing..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh already installed. Updating..."
    bash -c "$omz_dir/tools/upgrade.sh"
fi

# ===========================================
echo "4. Install or update Homebrew"
# ===========================================
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew already installed. Updating..."
    brew update
fi

# ===========================================
echo "5. Apply Brewfile for packages and casks"
# ===========================================
brewfile_tmp="/tmp/Brewfile"

curl -fsSL $FILES_BASE/homebrew/$profile/Brewfile -o "$brewfile_tmp"
if [ ! -s "$brewfile_tmp" ]; then
    echo "Failed to download Brewfile for packages and casks for profile $profile"
    exit 1
fi

echo "Backing up Brewfile for packages and casks..."
brew bundle dump --describe --force --no-vscode --file="$BACKUP_DIR/Backup_Brewfile_$TIMESTAMP"

brew bundle install --file="$brewfile_tmp"

# ===========================================
echo "6. Apply Brewfile for Go packages"
# ===========================================
brewfile_tmp_go="/tmp/Brewfile_go"

curl -fsSL $FILES_BASE/go/Brewfile -o "$brewfile_tmp_go"
if [ ! -s "$brewfile_tmp_go" ]; then
    echo "Failed to download Brewfile for Go packages"
    exit 1
fi

echo "Backing up Brewfile for Go packages ..."
brew bundle dump --force --go --file="$BACKUP_DIR/Backup_Brewfile_go_$TIMESTAMP"

brew bundle install --file="$brewfile_tmp_go"

# ===========================================
echo "7. Configure git and clone repos"
# ===========================================
if ! git config --global --get user.name >/dev/null; then
    read -rp "Enter your Git user name: " git_user_name
    git config --global user.name "$git_user_name"
else
    git_user_name=$(git config --global user.name)
    echo "Git user name already set: $git_user_name"
fi

if ! git config --global --get user.email >/dev/null; then
    read -rp "Enter your Git user email: " git_user_email
    git config --global user.email "$git_user_email"
else
    git_user_email=$(git config --global user.email)
    echo "Git user email already set: $git_user_email"
fi

git config --global ghq.root "$HOME/Git"

if ! gh auth status >/dev/null 2>&1; then
    echo "Authenticate GitHub in your browser using HTTPS. The script will continue once login is complete:"
    gh auth login
else
    echo "GitHub already authenticated — skipping login."
fi

github_user=$(gh api user --jq .login)
echo "Authenticated as: $github_user"
echo "Fetching all GitHub repos..."
for repo in $(gh repo list "$github_user" --limit 200 --json name,url -q '.[].url'); do
    ghq get "$repo" || echo "Already cloned or failed: $repo"
done

# ===========================================
echo "8. Install dotfiles"
# ===========================================
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
    if [ ! -s "$target" ]; then
        echo "Failed to install $filename in $target"
        exit 1
    fi
}

install_file "dotfiles/$profile/.zshrc" "$HOME/.zshrc"

# # TODO diff feature
# # TODO disable hot corners
# # TODO readme

# ===========================================
echo "9. Set up macOS"
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
app_list_url="$FILES_BASE/macos/$profile/dock.txt"
apps=()
curl -fsSL "$app_list_url" | while IFS= read -r line; do
    apps+=("$line")
done
bash -c "$(curl -fsSL $FILES_BASE/macos/dock.sh)" _ "${apps[@]}"

killall Dock
killall Finder
killall WindowManager

echo "Install Safari extensions"
ext_list_url="$FILES_BASE/macos/$profile/safari_extensions.txt"
extensions=()
curl -fsSL "$extension_list_url" | while IFS= read -r line; do
    extensions+=("$line")
done
bash -c "$(curl -fsSL $FILES_BASE/macos/extensions.sh)" _ "${extensions[@]}"

# ===========================================
echo "10. Set installed version"
# ===========================================
echo "$LATEST_VERSION" > "$VERSION_FILE"
echo "$profile" > "$PROFILE_FILE"
echo "✅ mac-provisioning $LATEST_VERSION installed"