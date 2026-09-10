#!/bin/bash

if rpm -q zoom >/dev/null 2>&1; then
    exit 0
fi

tmp_rpm="$(mktemp "${TMPDIR:-/tmp}"/zoom-XXXXXX.rpm)" || exit 0
chmod 644 "$tmp_rpm" 2>/dev/null || true
if curl -fsSL --retry 3 --retry-delay 2 "https://zoom.us/client/latest/zoom_x86_64.rpm" -o "$tmp_rpm"; then
    sudo dnf install -y "$tmp_rpm" || true
fi
rm -f "$tmp_rpm" || true
