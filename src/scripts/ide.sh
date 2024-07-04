#!/bin/bash

workingDirectory=$1

# Update ~/.vimrc
if [[ ! -f "$HOME/.vimrc" ]]; then
    cp "$workingDirectory/src/dotfiles/vim/.vimrc" "$HOME/.vimrc"
fi

# Neovim setup
if [[ ! -d "$HOME/.config/nvim/" ]]; then
    mkdir -p "$HOME/.config/"
    cp -r "$workingDirectory/src/dotfiles/nvim/" "$HOME/.config/nvim/"
    git clone --depth 1 https://github.com/wbthomason/packer.nvim \
    "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
    sudo pacman -S tree-sitter-cli --noconfirm
fi
