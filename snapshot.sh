#!/usr/bin/env bash
# ==================================================
# mac-provisioning - snapshot.sh
# Pulls local machine files into the cloned repo files for diffing.
# It overrides the corresponding profile files based on the
# installed profile so that changes can be inspected with git diff.
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

dock_current=$(defaults read com.apple.dock persistent-apps \
    | grep '_CFURLString"' \
    | sed 's/.*= "//; s/";$//' \
    | sed 's|^file://||; s|/$||' \
    | while read -r line; do
        printf '%b\n' "${line//%20/ }"
      done
)
echo "$dock_current" > "$target_dock"

extensions_plist="$HOME/Library/Safari/Extensions/Extensions.plist"
target_safari_extensions="$LOCAL_DIR/macos/$profile/safari_extensions.txt"
echo "Updating $target_safari_extensions from local Safari Extensions configuration"

if [[ -f "$extensions_plist" ]]; then
    plutil -convert xml1 -o - "$extensions_plist" 2>/dev/null \
    | grep -A1 '<key>CFBundleDisplayName</key>\|<key>iTunesStoreID</key>' \
    | sed -E 's/.*<string>(.*)<\/string>/\1/' \
    | paste - -d'|' \
    >> "$target_safari_extensions"
fi


# ==================================================
echo "DONE: Local machine snapshot taken. Use git diff to review changes."
# ==================================================