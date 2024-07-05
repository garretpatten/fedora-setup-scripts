#!/bin/bash

# Initial system update
sudo dnf update -y && sudo dnf upgrade -y && sudo dnf autoremove -y

# Git
if [[ ! -f "/usr/bin/git" ]]; then
    sudo dnf install git -y
fi
