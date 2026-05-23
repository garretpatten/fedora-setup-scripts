#!/bin/bash

# shellcheck source=../utils.sh
source "$(dirname "$0")/../utils.sh"

update_dnf_cache

office_packages=(
    "libreoffice-core"
    "libreoffice-calc"
    "libreoffice-writer"
    "libreoffice-impress"
    "libreoffice-draw"
    "libreoffice-langpack-en"
)
install_dnf_packages "${office_packages[@]}" || install_dnf_packages "libreoffice"

if flatpak remote-info flathub >/dev/null 2>&1; then
    flatpak install -y flathub us.zoom.Zoom 2>>"$ERROR_LOG_FILE" || true
fi

if flatpak remote-info flathub >/dev/null 2>&1; then
    flatpak install -y flathub org.standardnotes.standardnotes 2>>"$ERROR_LOG_FILE" || true
fi

productivity_packages=(
    "keepassxc"
    "redshift"
    "flameshot"
)
install_dnf_packages "${productivity_packages[@]}"

etcher_dir="$HOME/.local/bin"
etcher_path="$etcher_dir/balenaEtcher.AppImage"
if [[ ! -f "$etcher_path" ]]; then
    ensure_directory "$etcher_dir"
    install_dnf_packages "fuse-libs"
    install_dnf_packages "squashfuse" || true
    etcher_url=$(curl -s https://api.github.com/repos/balena-io/etcher/releases/latest 2>>"$ERROR_LOG_FILE" | grep "browser_download_url.*x86_64\\.AppImage" | head -1 | cut -d '"' -f 4)
    if [[ -z "$etcher_url" ]]; then
        etcher_url=$(curl -s https://api.github.com/repos/balena-io/etcher/releases/latest 2>>"$ERROR_LOG_FILE" | grep "browser_download_url.*x64\\.AppImage" | head -1 | cut -d '"' -f 4)
    fi
    if [[ -n "$etcher_url" ]]; then
        download_file_safe "$etcher_url" "$etcher_path"
        if [[ -f "$etcher_path" ]] && [[ -s "$etcher_path" ]]; then
            chmod +x "$etcher_path" 2>>"$ERROR_LOG_FILE" || true
        fi
    fi
fi
