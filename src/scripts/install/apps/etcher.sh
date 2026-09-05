#!/bin/bash

etcher_dir="$HOME/.local/bin"
etcher_path="$etcher_dir/balenaEtcher.AppImage"
[[ -f "$etcher_path" ]] && exit 0

mkdir -p "$etcher_dir"
sudo dnf install -y fuse-libs squashfuse || true

etcher_url=$(curl -fsSL https://api.github.com/repos/balena-io/etcher/releases/latest 2>/dev/null | \
    grep '"browser_download_url"' | grep -E 'x86_64\.AppImage|x64\.AppImage' | head -1 | cut -d '"' -f 4)

if [[ -z "$etcher_url" ]]; then
    exit 0
fi

if curl -fsSL --retry 3 --retry-delay 2 "$etcher_url" -o "$etcher_path"; then
    chmod +x "$etcher_path" || true
fi
