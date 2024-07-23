#!/bin/bash

workingDirectory=$1

### Authentication ###

# 1Password
if [[ ! -f "/usr/bin/1password" ]]; then
    # 1Password desktop app
    sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
    sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
    sudo dnf install 1password -y

    # 1Password CLI
    sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
    sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
    sudo dnf check-update -y 1password-cli && sudo dnf install 1password-cli
fi

# Hardware keys
if [[ -f "/usr/bin/pamu2fcfg" ]]; then
    echo "pam modules are already installed."
else
    sudo dnf install pam pam-u2f pamu2fcfg -y
fi

if [[ ! -f "/etc/yubico/u2f_keys" ]]; then
    mkdir -p ~/.config/yubico

    printf "\n\n\nHardware Key Registration\n\n\n"

    # Register the primary key.
    pamu2fcfg >> ~/.config/yubico/u2f_keys

    # Register the backup key.
    pamu2fcfg >> ~/.config/yubico/u2f_keys

    sudo mkdir -p /etc/yubico
    sudo cp ~/.config/yubico/u2f_keys /etc/yubico/u2f_keys
    sudo chmod 644 /etc/yubico/u2f_keys

    # Authentication updates
    # TODO: Add python script to update /etc/pam.d/sudo to add: auth sufficient pam_u2f.so authfile=/etc/yubico/u2f_keys
fi

### Defensive Security ###

# Clam AV
if [[ ! -f "/usr/bin/clamscan" ]]; then
    sudo dnf install clamav -y
fi

# Firewall
if [[ ! -f "/usr/sbin/ufw" ]]; then
    sudo dnf install ufw -y
fi

sudo ufw enable

### Privacy ###

# Proton VPN, Proton VPN CLI
if [[ ! -f "/usr/bin/protonvpn" ]]; then
    cd "$HOME/Downloads" || return

    wget https://protonvpn.com/download/protonvpn-stable-release-1.0.1-1.noarch.rpm
    cd "$workingDirectory" || return
    sudo dnf install ~/Downloads/protonvpn-stable-release-1.0.1-1.noarch.rpm -y
    sudo dnf update -y
    sudo dnf install protonvpn-cli -y

    # Dependencies for alternative routing.
    sudo dnf install --user 'dnspython>=1.16.0' -y
fi

# Signal Messenger
if [[ ! -d "/var/lib/flatpak/app/org.signal.Signal" && ! -d "$HOME/.local/share/flatpak/app/org.signal.Signal" ]]; then
    flatpak install flathub "org.signal.Signal" -y
fi
