#!/bin/bash

install_flatpak_if_missing() {
    local app_id="$1"

    if flatpak list --app --columns=application 2>/dev/null | grep -qx "$app_id"; then
        return 0
    fi

    flatpak install -y flathub "$app_id" || true
}

install_flatpaks_from_file() {
    local flatpaks_file="$1"
    local line app_id

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        read -r app_id _ <<< "$line"
        install_flatpak_if_missing "$app_id"
    done < "$flatpaks_file"
}
