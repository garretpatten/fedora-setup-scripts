#!/bin/bash

# shellcheck source=../utils.sh
source "$(dirname "$0")/../utils.sh"

update_dnf_cache

dnf_quiet_best_effort upgrade -y || true
dnf_quiet_best_effort autoremove -y || true

if command -v docker >/dev/null 2>&1; then
    sudo systemctl enable docker.service 2>>"$ERROR_LOG_FILE" || true
    sudo systemctl start docker.service 2>>"$ERROR_LOG_FILE" || true
    sudo usermod -aG docker "$USER" 2>>"$ERROR_LOG_FILE" || true
fi

if command -v ufw >/dev/null 2>&1 && ufw_configure_ok; then
    sudo ufw --force enable 2>>"$ERROR_LOG_FILE" || true
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
