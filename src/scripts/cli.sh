#!/bin/bash

cliTools=("alacritty" "bat" "curl" "exa" "eza" "fastfetch" "fd" "htop" "jq" "neovim" "openvpn" "rigrep" "terminator" "tmux" "vim" "wget" "zsh")
for cliTool in "${cliTools[@]}"; do
    if [[ ! -f "/usr/bin/$cliTool" && ! -f "/usr/sbin/$cliTool" ]]; then
        sudo dnf install "$cliTool" --y
    fi
done

### Additional package managers ###

# Flatpak
if [[ ! -f "/usr/bin/flatpak" ]]; then
    sudo dnf install flatpak -y
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi
