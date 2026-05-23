#!/bin/bash

# Firewall posture (prefer UFW defaults on developer workstations mirroring sibling Ubuntu scripts).
# Fedora Workstation ships firewalld by default — stop/disable it before enabling UFW to avoid clashes.

# shellcheck source=../utils.sh
source "$(dirname "$0")/../utils.sh"

if ! command -v ufw >/dev/null 2>&1; then
    exit 0
fi

if ! ufw_configure_ok; then
    exit 0
fi

if systemctl list-unit-files | grep -q '^firewalld\.service'; then
    sudo systemctl stop firewalld >/dev/null 2>&1 || true
    sudo systemctl disable firewalld >/dev/null 2>&1 || true
fi

sudo ufw --force reset >/dev/null 2>&1 || true
sudo ufw default deny incoming >/dev/null 2>&1 || true
sudo ufw default allow outgoing >/dev/null 2>&1 || true
sudo ufw allow ssh >/dev/null 2>&1 || true
sudo ufw --force enable >/dev/null 2>&1 || true
