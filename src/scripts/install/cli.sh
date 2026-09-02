#!/bin/bash

# shellcheck source=../utils.sh
source "$(dirname "$0")/../utils.sh"

update_dnf_cache

install_dnf_packages "flatpak"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

cli_tools=(
    "bat"
    "curl"
    "eza"
    "fd"
    "fzf"
    "gcc"
    "git"
    "htop"
    "jq"
    "libsecret"
    "libsecret-devel"
    "make"
    "pkgconf"
    "ripgrep"
    "tealdeer"
    "tree-sitter-cli"
    "vim-enhanced"
    "wget"
    "whois"
    "btop"
    "fastfetch"
    "zoxide"
)
install_dnf_packages "${cli_tools[@]}"
