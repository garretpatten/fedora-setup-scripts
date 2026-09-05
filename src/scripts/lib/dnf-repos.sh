#!/bin/bash

# COPR and third-party repository helpers.

enable_copr_if_available() {
    local copr="$1"
    if dnf copr list --enabled 2>/dev/null | grep -q "^${copr}$"; then
        return 0
    fi
    sudo dnf copr enable -y "$copr" || true
}
