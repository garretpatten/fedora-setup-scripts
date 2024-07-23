#!/bin/bash

workingDirectory=$1

# Change root and user shell to zsh
if [[ -f "/usr/bin/zsh" ]]; then
    sudo chsh -s "$(which zsh)"
    chsh -s "$(which zsh)"
fi

### Install fonts ###

# Awesome Terminal Fonts
if [[ ! -d "/usr/share/fonts/awesome-terminal-fonts/" ]]; then
    # TODO
fi

# Fira Code Fonts
if [[ ! -d "/usr/share/fonts/FiraCode/" ]]; then
    # TODO
fi

if [[ ! -d "/usr/share/fonts/TTF/" ]]; then
    # TODO
fi

# Powerline Fonts
if [[ ! -d "/usr/share/fonts/OTF/" ]]; then
    sudo dnf install powerline-fonts -y
fi

### Install oh-my-posh ###
if [[ ! -f "/usr/bin/oh-my-posh" ]]; then
    # TODO
fi

### Zsh Plugins ###

# Zsh Autosuggestions
if [[ ! -d "/usr/share/zsh/plugins/zsh-autosuggestions/" ]]; then
    sudo dnf install zsh-autosuggestions -y
fi

# Zsh Syntax Highlighting
if [[ ! -d "/usr/share/zsh/plugins/zsh-syntax-highlighting/" ]]; then
    sudo dnf install zsh-syntax-highlighting -y
fi

### Terminal Configuration ###

# Configure Alacritty
if [[ ! -d "$HOME/.config/alacritty/" ]]; then
    mkdir -p "$HOME/.config/alacritty"
    git clone https://github.com/alacritty/alacritty-theme "$HOME/.config/alacritty/"
    touch "$HOME/.config/alacritty/alacritty.toml"
    cp "$workingDirectory/src/dotfiles/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
fi

# Update ~/.zshrc
cp "$workingDirectory/src/dotfiles/oh-my-posh/.zshrc" "$HOME/.zshrc"
