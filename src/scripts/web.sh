#!/bin/bash

# Brave
if [[ ! -f "/usr/bin/brave-browser" ]]; then
    sudo dnf install dnf-plugins-core -y
    sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    sudo dnf install brave-browser -y
fi
