install/update mac-provisioning: /bin/bash -c "$(curl -sL https://raw.githubusercontent.com/sergicanet9/mac-provisioning/main/setup.sh)"

dump homebrew + go packages: brew bundle dump --describe --force --no-vscode
install homebrew + go packages: brew bundle install --file=Brewfile