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
    sudo systemctl stop firewalld 2>>"$ERROR_LOG_FILE" || true
    sudo systemctl disable firewalld 2>>"$ERROR_LOG_FILE" || true
fi

sudo ufw --force reset 2>>"$ERROR_LOG_FILE" || true
sudo ufw default deny incoming 2>>"$ERROR_LOG_FILE" || true
sudo ufw default allow outgoing 2>>"$ERROR_LOG_FILE" || true
sudo ufw allow ssh 2>>"$ERROR_LOG_FILE" || true
sudo ufw --force enable 2>>"$ERROR_LOG_FILE" || true
