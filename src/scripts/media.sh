#!/bin/bash

# Spotify
if [[ ! -d "/usr/bin/spotify-launcher" ]]; then
    sudo pacman -S spotify-launcher --noconfirm
fi

# VLC
if [[ ! -f "/usr/bin/vlc" ]]; then
    sudo pacman -S vlc --noconfirm
fi
