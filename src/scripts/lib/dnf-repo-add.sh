#!/bin/bash

import_rpm_key_if_missing() {
    local key_url="$1"
    local key_id="$2"

    if [[ -n "$key_id" ]] && rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\n' 2>/dev/null | grep -qi "$key_id"; then
        return 0
    fi

    local key_file
    key_file="$TEMP_DIR/repo-key-$(basename "$key_url").asc"
    if curl -fsSL "$key_url" -o "$key_file" 2>/dev/null; then
        sudo rpmkeys --import "$key_file" || true
    fi
}

install_repo_file_from_url() {
    local repo_url="$1"
    local repo_file="$2"

    if [[ -f "$repo_file" ]]; then
        return 0
    fi

    local tmp_file
    tmp_file="$TEMP_DIR/repo-$(basename "$repo_file")"
    if curl -fsSL "$repo_url" -o "$tmp_file" 2>/dev/null; then
        sudo install -Dm644 "$tmp_file" "$repo_file" || true
    fi
}

setup_docker_repo() {
    local repo_file="/etc/yum.repos.d/docker-ce.repo"
    [[ -f "$repo_file" ]] && return 0

    import_rpm_key_if_missing "https://download.docker.com/linux/fedora/gpg" "docker"
    install_repo_file_from_url "https://download.docker.com/linux/fedora/docker-ce.repo" "$repo_file"
}

setup_brave_repo() {
    local repo_file="/etc/yum.repos.d/brave-browser.repo"
    [[ -f "$repo_file" ]] && return 0

    import_rpm_key_if_missing "https://brave-browser-rpm-release.s3.brave.com/brave-core.asc" "brave"
    install_repo_file_from_url "https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo" "$repo_file"
}

setup_nodesource_repo() {
    local node_major="${1:-24}"
    local repo_file="/etc/yum.repos.d/nodesource-nsolid.repo"
    [[ -f "$repo_file" ]] && return 0

    import_rpm_key_if_missing "https://rpm.nodesource.com/gpgkey/nodesource.gpg.key" "nodesource"
    install_repo_file_from_url "https://rpm.nodesource.com/setup_${node_major}.x" "$TEMP_DIR/nodesource_setup.sh" || return 0
    if [[ -f "$TEMP_DIR/nodesource_setup.sh" ]]; then
        sudo bash "$TEMP_DIR/nodesource_setup.sh" || true
    fi
}

setup_repo_from_manifest_line() {
    local kind="$1"
    shift

    case "$kind" in
        docker)
            setup_docker_repo
            ;;
        brave)
            setup_brave_repo
            ;;
        nodesource)
            setup_nodesource_repo "$1"
            ;;
        rpm-key)
            local key_url="$1"
            local key_id="$2"
            import_rpm_key_if_missing "$key_url" "$key_id"
            ;;
        repo-url)
            local repo_url="$1"
            local repo_file="$2"
            install_repo_file_from_url "$repo_url" "$repo_file"
            ;;
    esac
}
