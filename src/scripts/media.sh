#!/bin/bash

# Spotify
if [[ ! -d "/usr/bin/spotify-launcher" ]]; then
    # sudo dnf install spotify -y
fi

# VLC
if [[ ! -f "/usr/bin/vlc" ]]; then
    sudo dnf install vlc -y
fi
