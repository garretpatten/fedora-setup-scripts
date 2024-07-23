#!/bin/bash

### Payloads ###

# Payloads All the Things
git clone https://github.com/swisskyrepo/PayloadsAllTheThings "$HOME/Hacking/"

# SecLists
git clone https://github.com/danielmiessler/SecLists "$HOME/Hacking/"

### Tools ###

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
