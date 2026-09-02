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

# LocalSend
sudo ufw allow 53317/udp >/dev/null 2>&1 || true
sudo ufw allow 53317/tcp >/dev/null 2>&1 || true

# Docker DNS on host
sudo ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment 'allow-docker-dns' >/dev/null 2>&1 || true
sudo ufw allow in proto udp from 192.168.0.0/16 to 172.17.0.1 port 53 comment 'allow-docker-dns' >/dev/null 2>&1 || true

if command -v ufw-docker >/dev/null 2>&1; then
    sudo ufw-docker install >/dev/null 2>&1 || true
    sudo ufw reload >/dev/null 2>&1 || true
fi

sudo ufw --force enable >/dev/null 2>&1 || true
