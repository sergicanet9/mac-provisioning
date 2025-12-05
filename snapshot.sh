#!/usr/bin/env bash
# ==================================================
# mac-provisioning - snapshot.sh
# Takes a snapshot of the local machine configuration.
# ==================================================

# ===========================================
# Variables
# ===========================================
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"
declare profile

# ===========================================
echo "1. Check installed profile"
# ===========================================
profile_file="$HOME/.mac-provisioning/profile"
if [[ ! -f "$profile_file" ]]; then
    echo "No profile found at $profile_file. Make sure that mac-provisioning is installed."
    exit 1
fi

profile=$(cat "$profile_file")
echo "Taking local machine snapshot for profile: $profile"

# ==================================================
echo "1. Update Brewfile for packages and casks"
# ==================================================
target_brewfile="$LOCAL_DIR/homebrew/$profile/Brewfile"

echo "Generating Brewfile for packages and casks..."
brew bundle dump --describe --force --no-vscode --no-go --file="$target_brewfile"
echo "Updated Brewfile at: $target_brewfile"

# ==================================================
echo "2. Update Brewfile for Go packages"
# ==================================================
target_brewfile_go="$LOCAL_DIR/go/Brewfile"

echo "Generating Brewfile for Go packages..."
brew bundle dump --describe --force --go --file="$target_brewfile_go"
echo "Updated Brewfile at: $target_brewfile_go"

# ==================================================
echo "3. Update dotfiles"
# ==================================================
source_zshrc="$HOME/.zshrc"
target_zshrc="$LOCAL_DIR/dotfiles/$profile/.zshrc"

if [[ ! -f "$source_zshrc" ]]; then
    echo "No ~/.zshrc found on the system"
    exit 1
else
    echo "Updating $target_zshrc from local ~/.zshrc"
    cp "$source_zshrc" "$target_zshrc"
fi

# ==================================================
echo "4. Update macOS files"
# ==================================================
target_dock="$LOCAL_DIR/macos/$profile/dock.txt"
echo "Updating $target_dock from local Dock configuration"

source_dock=$(defaults read com.apple.dock persistent-apps \
    | grep '_CFURLString"' \
    | sed 's/.*= "//; s/";$//' \
    | sed 's|^file://||; s|/$||' \
    | while read -r line; do
        printf '%b\n' "${line//%20/ }"
      done
)
echo "$source_dock" > "$target_dock"

# ==================================================
echo "DONE: Local machine snapshot taken. Use git diff to review changes."
# ==================================================