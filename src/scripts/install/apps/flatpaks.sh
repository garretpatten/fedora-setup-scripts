#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/flatpak-install.sh
source "$DIR/../../lib/flatpak-install.sh"

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
install_flatpaks_from_file "$DIR/../flatpaks.txt"
