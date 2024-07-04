#!/bin/bash

# Brave
if [[ ! -f "/usr/bin/brave-browser" ]]; then
    yay -S brave-bin --noconfirm
fi
