#!/bin/bash

# shellcheck source=../utils.sh
source "$(dirname "$0")/../utils.sh"

update_dnf_cache

# Node.js LTS/current from NodeSource RPM repository (Fedora-supported).
NODE_MAJOR=24
nodesource_setup="$TEMP_DIR/nodesource_setup.sh"
download_file_safe "https://rpm.nodesource.com/setup_${NODE_MAJOR}.x" "$nodesource_setup"
if ! run_capture_on_fail "NodeSource Fedora setup (${NODE_MAJOR}.x)" sudo bash "$nodesource_setup"; then
    log_error "NodeSource Fedora setup returned non-zero (continuing if nodejs installed)"
fi
install_dnf_packages "nodejs"

if [[ ! -d "$HOME/.nvm" ]]; then
    nvm_install_script="$TEMP_DIR/nvm_install.sh"
    download_file_safe "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh" "$nvm_install_script"
    bash "$nvm_install_script" 2>>"$ERROR_LOG_FILE" || true
fi

python_packages=(
    "python3"
    "python3-pip"
    "python3-devel"
)
install_dnf_packages "${python_packages[@]}"

if command -v npm >/dev/null 2>&1; then
    sudo npm install -g @vue/cli --loglevel=error --no-update-notifier 2>>"$ERROR_LOG_FILE" || true
fi

# DNF 5 dropped `config-manager --add-repo`; install the upstream .repo like other third‑party RPM sources.
if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
    if download_file_safe "https://download.docker.com/linux/fedora/docker-ce.repo" "$TEMP_DIR/docker-ce.repo"; then
        sudo install -Dm644 "$TEMP_DIR/docker-ce.repo" /etc/yum.repos.d/docker-ce.repo 2>>"$ERROR_LOG_FILE" || true
        update_dnf_cache || true
    fi
fi

docker_packages=(
    "docker-ce"
    "docker-ce-cli"
    "containerd.io"
    "docker-compose-plugin"
)
install_dnf_packages "${docker_packages[@]}" || true

neovim_packages=(
    "neovim"
    "python3-neovim"
)
install_dnf_packages "${neovim_packages[@]}"

dev_tools=(
    "gh"
    "shellcheck"
    "git"
)
install_dnf_packages "${dev_tools[@]}"

if flatpak remote-info flathub >/dev/null 2>&1; then
    flatpak install -y flathub com.getpostman.Postman 2>>"$ERROR_LOG_FILE" || true
fi

run_capture_on_fail "pip install semgrep (user)" env PIP_ROOT_USER_ACTION=ignore pip3 install --user semgrep || true

sg_binary="$TEMP_DIR/sg"
download_file_safe "https://sourcegraph.com/.api/src-cli/src_linux_amd64" "$sg_binary"
if [[ -f "$sg_binary" ]]; then
    chmod +x "$sg_binary" 2>>"$ERROR_LOG_FILE" || true
    sudo mv "$sg_binary" /usr/local/bin/sg 2>>"$ERROR_LOG_FILE" || true
fi
