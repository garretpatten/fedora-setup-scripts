#!/bin/bash

sudo dnf install -y dnf-automatic || true

sudo bash -c '
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable dnf-automatic.timer >/dev/null 2>&1 || true
    systemctl start dnf-automatic.timer >/dev/null 2>&1 || true
fi
' || true
