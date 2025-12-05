install/update mac-provisioning: /bin/bash -c "$(curl -sL https://raw.githubusercontent.com/sergicanet9/mac-provisioning/main/setup.sh)"

dump homebrew: brew bundle dump --describe --force --no-vscode --no-go
dump go packages: brew bundle dump --describe --force --go
install homebrew + go packages: brew bundle install --file=Brewfile

VERSION FILE is handled automatically 