#!/bin/bash

workingDirectory=$1

# Vim configuration
if [[ ! -f "$HOME/.vimrc" ]]; then
    cp "$workingDirectory/src/dotfiles/vim/.vimrc" "$HOME/.vimrc"
fi

# Neovim setup
if [[ ! -d "$HOME/.config/nvim/" ]]; then
    mkdir -p "$HOME/.config/"
    cp -r "$workingDirectory/src/dotfiles/nvim/" "$HOME/.config/nvim/"
    git clone --depth 1 https://github.com/wbthomason/packer.nvim \
    "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
    sudo dnf install tree-sitter-cli -y
fi

# VS Code
if [[ ! -f "/usr/bin/code" ]]; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf check-update -y
    sudo dnf install code -y
fi
