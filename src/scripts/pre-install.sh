#!/bin/bash

workingDirectory=$1

# Initial system update
sudo dnf update -y && sudo dnf upgrade -y && sudo dnf autoremove -y

if [[ ! -f "/usr/bin/git" ]]; then
    sudo dnf install git -y
fi
