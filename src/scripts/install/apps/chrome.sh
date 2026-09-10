#!/bin/bash

if command -v google-chrome-stable >/dev/null 2>&1; then
    exit 0
fi
if rpm -q google-chrome-stable >/dev/null 2>&1; then
    exit 0
fi

sudo dnf install -y fedora-workstation-repositories 2>/dev/null || true
sudo dnf5 config-manager setopt google-chrome.enabled=1 2>/dev/null || sudo dnf config-manager --set-enabled google-chrome 2>/dev/null || true
if ! sudo dnf install -y google-chrome-stable || ! command -v google-chrome-stable >/dev/null 2>&1; then
    sudo dnf install -y "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" || true
fi
if ! command -v google-chrome-stable >/dev/null 2>&1 && ! rpm -q google-chrome-stable >/dev/null 2>&1; then
    tmp_rpm="$(mktemp "${TMPDIR:-/tmp}"/google-chrome-XXXXXX.rpm)" || exit 0
    chmod 644 "$tmp_rpm" 2>/dev/null || true
    if curl -fsSL "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" -o "$tmp_rpm"; then
        sudo dnf install -y "$tmp_rpm" || true
    fi
    rm -f "$tmp_rpm" || true
fi
