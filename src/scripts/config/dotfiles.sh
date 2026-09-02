#!/bin/bash

# Symlink every src/dotfiles/config/<app>/ directory into ~/.config/<app>/ and copy
# manifest-listed files. Mirrors ubuntu-setup-scripts src/scripts/config/dotfiles.sh.

# shellcheck source=../utils.sh
source "$(dirname "$0")/../utils.sh"

link_dotfiles_xdg_config_dirs
install_dotfiles_from_manifest "$(dirname "$0")/dotfiles.manifest"
