# mac-provisioning
My automated macOS setup and configuration for software development.

## 🚀 Features
- Install or update the mac-provisioning setup **idempotently**.
- Configure **Xcode command line tools**, **Oh My Zsh**, **Homebrew packages and casks**, **Go packages**, **Git**, **Dotfiles** and **macOS settings** on one go.
- Support for multiple **profiles** with separate configuration files.
- **Backup** existing files before overwriting.
- **Snapshot** tool to identify changes between the local machine and the repository setup.

## 🏁 Getting Started
Run the installer with a single command:
```
/bin/bash -c "$(curl -sL https://raw.githubusercontent.com/sergicanet9/mac-provisioning/main/setup.sh)"
```
The same command can be run multiple times. It will detect existing installations and update as needed.

## 👤 Profiles
The project comes with two predefined profiles, which can be selected at install time: **personal** and **work**. Each of them has specific configurations for:
- Homebrew packages and casks
- .zshrc file
- macOS Dock apps
- Safari extensions

## 🛠️ Snapshot tool 
The project includes a snapshot script to identify local changes being made outside mac-provisioning. Once the project is cloned, run it with:
```
./snapshot.sh
```
The script pulls the local machine configuration back into the cloned repository, overriding the corresponding files based on the installed profile. It creates a snapshot of:
- Homebrew packages and casks
- Go packages
- .zshrc file
- macOS Dock apps

After the execution, the changes in the local machine can be compared with the repository setup using `git diff`.

## 📤 Versioning
After pushing a new `tag`, the CD GitHub Action commits the new version number into the [VERSION](https://github.com/sergicanet9/mac-provisioning/blob/main/VERSION) file so that it can be easily tracked on installations and updates.

## ✍️ Author
Sergi Canet Vela

## ⚖️ License
This project is licensed under the terms of the MIT license.