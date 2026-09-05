#!/bin/bash

if command -v google-chrome-stable >/dev/null 2>&1; then
    exit 0
fi
if rpm -q google-chrome-stable >/dev/null 2>&1; then
    exit 0
fi

sudo dnf install -y fedora-workstation-repositories 2>/dev/null || true
sudo dnf config-manager --set-enabled google-chrome 2>/dev/null || true
sudo dnf install -y google-chrome-stable || true
