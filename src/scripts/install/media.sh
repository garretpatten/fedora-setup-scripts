#!/bin/bash

# shellcheck source=../utils.sh
source "$(dirname "$0")/../utils.sh"

update_dnf_cache

# Brave publishes an RPM `.repo` for Fedora-compatible systems.
sudo rpmkeys --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc 2>>"$ERROR_LOG_FILE" || true

if [[ ! -f /etc/yum.repos.d/brave-browser.repo ]]; then
    if download_file_safe "https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo" "$TEMP_DIR/brave-browser.repo"; then
        sudo install -Dm644 "$TEMP_DIR/brave-browser.repo" /etc/yum.repos.d/brave-browser.repo 2>>"$ERROR_LOG_FILE" || true
    fi
    update_dnf_cache
fi

install_dnf_packages "brave-browser"

install_dnf_packages "vlc"

# Fedora exposes patent-safe FFmpeg as ffmpeg-free; libs are bundled (no ffmpeg-libs metapackage).
if ! rpm -q ffmpeg-free >/dev/null 2>&1 && ! rpm -q ffmpeg >/dev/null 2>&1; then
    ffmpeg_tmp=$(mktemp)
    if ! { sudo dnf install -y ffmpeg-free; } >"$ffmpeg_tmp" 2>&1 \
        && ! { sudo dnf install -y ffmpeg; } >"$ffmpeg_tmp" 2>&1; then
        cat "$ffmpeg_tmp" >>"$ERROR_LOG_FILE"
        log_error "Could not install ffmpeg-free or ffmpeg (enable RPM Fusion for full codecs if needed)."
    fi
    rm -f "$ffmpeg_tmp"
fi

if flatpak remote-info flathub >/dev/null 2>&1; then
    flatpak install -y flathub com.spotify.Client 2>>"$ERROR_LOG_FILE" || true
fi
