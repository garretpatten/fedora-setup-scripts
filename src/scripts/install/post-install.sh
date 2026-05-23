#!/bin/bash

# shellcheck source=../utils.sh
source "$(dirname "$0")/../utils.sh"

update_dnf_cache

dnf_quiet_best_effort upgrade -y || true
dnf_quiet_best_effort autoremove -y || true

if command -v docker >/dev/null 2>&1; then
    sudo systemctl enable docker.service >/dev/null 2>&1 || true
    sudo systemctl start docker.service >/dev/null 2>&1 || true
    docker_grant_user="${SUDO_USER:-${USER:-}}"
    [[ -n "$docker_grant_user" ]] || docker_grant_user="$(logname 2>/dev/null || true)"
    [[ -n "$docker_grant_user" ]] || docker_grant_user="$(id -un 2>/dev/null || true)"
    if [[ -n "$docker_grant_user" ]] && [[ "$docker_grant_user" != root ]] && id "$docker_grant_user" &>/dev/null; then
        sudo usermod -aG docker "$docker_grant_user" >/dev/null 2>&1 || true
    fi
fi

if command -v ufw >/dev/null 2>&1 && ufw_configure_ok; then
    sudo ufw --force enable >/dev/null 2>&1 || true
fi

fedora_art_file="$PROJECT_ROOT/src/assets/fedora.txt"
if [[ -f "$fedora_art_file" ]]; then
    echo
    echo "============================================================================"
    cat "$fedora_art_file" 2>/dev/null || true
    echo "============================================================================"
    echo
fi

echo "Setup completed. Check $ERROR_LOG_FILE for any errors."
