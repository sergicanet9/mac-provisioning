#!/usr/bin/env bash
# ==================================================
# mac-provisioning - setup.sh
# Installs or updates mac-provisioning on a Mac.
# ==================================================

VERSION_FILE="$HOME/.mac_provisioning_version"
VERSION_URL="https://raw.githubusercontent.com/sergicanet9/mac-provisioning/main/VERSION"

LATEST_VERSION=$(curl -sL -H "Cache-Control: no-cache" "$VERSION_URL")
if [ -z "$LATEST_VERSION" ]; then
    echo "Could not fetch VERSION from $VERSION_URL"
    exit 1
fi

if [ ! -f "$VERSION_FILE" ]; then
    echo "mac-provisioning is not installed. Proceeding with installation..."
    NEW_INSTALLATION=true
else
    INSTALLED_VERSION=$(cat "$VERSION_FILE")

    if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
        echo "✅ mac-provisioning is already up to date. Current version: $INSTALLED_VERSION"
        exit 0
    else
        echo "mac-provisioning $INSTALLED_VERSION installed. Updating to $LATEST_VERSION..."
        NEW_INSTALLATION=false
    fi
fi

echo "$LATEST_VERSION" > "$VERSION_FILE"
echo "✅ mac-provisioning $LATEST_VERSION installed"