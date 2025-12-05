#!/usr/bin/env bash
# ==================================================
# extensions.sh - Asks to install Safari extensions
# ==================================================

extensions=(
    "AdBlock|1402042596"
    "1Password|1569813296"
)

for ext in "${extensions[@]}"; do
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