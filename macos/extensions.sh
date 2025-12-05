#!/usr/bin/env bash
# ==================================================
# extensions.sh - Asks to install Safari extensions
# ==================================================

extensions=(
    "1402042596"  # AdBlock
    "1569813296"  # 1Password
)

for ext_id in "${extensions[@]}"; do
    read -rp "Do you want to install extension with App Store ID $ext_id? (y/n) " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        open "macappstore://itunes.apple.com/app/id$ext_id"
        echo "Please complete the installation manually in App Store."
    else
        echo "Skipping extension $ext_id."
    fi
done