#!/bin/bash

if rpm -q proton-vpn-gnome-desktop >/dev/null 2>&1; then
    exit 0
fi

fc=""
if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    fc="${VERSION_ID:-}"
fi
[[ -z "$fc" ]] && fc="$(rpm -E %fedora 2>/dev/null || echo "")"
[[ -z "$fc" ]] && fc="40"

protonvpn_release_rpm="$TEMP_DIR/protonvpn-stable-release.rpm"
protonvpn_repo_urls=(
    "https://repo.protonvpn.com/fedora-${fc}-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.4-1.noarch.rpm"
    "https://repo.protonvpn.com/fedora-${fc}-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.8-1.noarch.rpm"
)

protonvpn_repo_installed=0
for proton_url in "${protonvpn_repo_urls[@]}"; do
    [[ -z "$proton_url" ]] && continue
    rm -f "$protonvpn_release_rpm" 2>/dev/null || true
    if curl -fsSL --connect-timeout 30 --max-time 120 "$proton_url" -o "$protonvpn_release_rpm" 2>/dev/null \
        && [[ -s "$protonvpn_release_rpm" ]]; then
        sudo rpm -Uvh "$protonvpn_release_rpm" || sudo rpm -ivh "$protonvpn_release_rpm" || true
        protonvpn_repo_installed=1
        sudo dnf makecache -y || true
        break
    fi
done

if [[ "$protonvpn_repo_installed" -eq 1 ]]; then
    sudo dnf install -y proton-vpn-gnome-desktop libappindicator-gtk3 gnome-extensions-app gnome-shell-extension-appindicator || true
fi
