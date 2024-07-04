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
    # TODO
fi

# Network Mapper
if [[ ! -f "/usr/bin/nmap" ]]; then
    sudo dnf install nmap -y
fi

# ZAP
if [[ ! -f "/usr/bin/zaproxy" ]]; then
    flatpak install flathub org.zaproxy.ZAP
fi
