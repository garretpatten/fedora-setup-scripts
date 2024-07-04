#!/bin/bash

workingDirectory=$1

### Payloads ###

# Payloads All the Things
git clone https://github.com/swisskyrepo/PayloadsAllTheThings "$HOME/Hacking/"

# SecLists
git clone https://github.com/danielmiessler/SecLists "$HOME/Hacking/"

### Tools ###

# Black Arch tools
cd "$HOME/Hacking/" || return
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
sudo ./strap.sh
cd "$workingDirectory" || return

# Burp Suite
if [[ ! -f "/usr/bin/burpsuite" ]]; then
    yay -S burpsuite --noconfirm
fi

# Network Mapper
if [[ ! -f "/usr/bin/nmap" ]]; then
    sudo pacman -S nmap --noconfirm
fi

# ZAP
if [[ ! -f "/usr/bin/zaproxy" ]]; then
    sudo pacman -S zaproxy --noconfirm
fi
