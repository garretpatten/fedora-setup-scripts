#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/env.sh
source "$DIR/../../lib/env.sh"

if rpm -q bruno >/dev/null 2>&1; then
    exit 0
fi

rpm_url=$(curl -fsSL https://api.github.com/repos/usebruno/bruno/releases/latest 2>/dev/null | \
    grep '"browser_download_url"' | grep -E 'x86_64.*\.rpm' | head -1 | cut -d '"' -f 4)

[[ -z "$rpm_url" ]] && exit 0

if curl -fsSL --retry 3 --retry-delay 2 "$rpm_url" -o "$TEMP_DIR/bruno.rpm"; then
    chmod 644 "$TEMP_DIR/bruno.rpm" 2>/dev/null || true
    sudo dnf install -y "$TEMP_DIR/bruno.rpm" || true
fi
rm -f "$TEMP_DIR/bruno.rpm" || true
