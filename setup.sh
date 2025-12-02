#!/usr/bin/env bash
# ==================================================
# mac-provisioning - setup.sh
# Installs or updates mac-provisioning on a Mac.
# ==================================================

#!/usr/bin/env bash
# ==================================================
# setup.sh - minimal mac-provisioning
# Detecta nueva instalación o actualización
# ==================================================

VERSION_FILE="$HOME/.mac_provisioning_version"
VERSION_URL="https://raw.githubusercontent.com/sergicanet9/mac-provisioning/main/VERSION"

LATEST_VERSION=$(curl -sL "$VERSION_URL")
if [ -z "$LATEST_VERSION" ]; then
    echo "Could not fetch VERSION from $VERSION_URL"
    exit 1
fi

if [ ! -f "$VERSION_FILE" ]; then
    echo "New installation"
    NEW_INSTALLATION=true
else
    INSTALLED_VERSION=$(cat "$VERSION_FILE")
    echo "Current version: $INSTALLED_VERSION"
    NEW_INSTALLATION=false
fi

echo "$LATEST_VERSION" > "$VERSION_FILE"
echo "📄 Version saved: $LATEST_VERSION"