#!/bin/bash

if command -v ghostty >/dev/null 2>&1 || rpm -q ghostty >/dev/null 2>&1; then
    exit 0
fi

sudo dnf install -y ghostty || true
