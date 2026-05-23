#!/bin/bash

# shellcheck source=../utils.sh
source "$(dirname "$0")/../utils.sh"

update_dnf_cache

sudo dnf upgrade -y 2>>"$ERROR_LOG_FILE" || true
sudo dnf autoremove -y 2>>"$ERROR_LOG_FILE" || true

essential_tools=(
    "git"
    "curl"
    "wget"
    "ca-certificates"
    "gnupg"
    "dnf-plugins-core"
    "unzip"
    "file"
)
install_dnf_packages "${essential_tools[@]}"

if [[ "$(timedatectl show --property=Timezone --value 2>/dev/null)" == "UTC" ]]; then
    sudo timedatectl set-timezone America/New_York 2>>"$ERROR_LOG_FILE" || true
fi
