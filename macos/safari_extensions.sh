#!/usr/bin/env bash
# ==================================================
# extensions.sh - Asks to install Safari extensions
# ==================================================

if [ "$#" -eq 0 ]; then
    echo "No extensions provided. Exiting."
    exit 1
fi

for ext in "$@"; do
    name="${ext%%|*}"
    id="${ext##*|}"
    read -rp "Do you want to install $name (App Store ID: $id)? (y/n) " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        open "macappstore://itunes.apple.com/app/id$id"
        echo "Complete the installation of $name manually in App Store."
    else
        echo "Skipping $name."
    fi
done
