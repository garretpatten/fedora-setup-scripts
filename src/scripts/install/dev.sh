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
install_dnf_packages "python3-virtualenv" || true

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
    "golang"
)
install_dnf_packages "${dev_tools[@]}"

# Build essentials and language runtimes for LSP support (Ubuntu build-essential/lsp.packages parity).
lsp_packages=(
    "gcc-c++"
    "glibc-devel"
    "kernel-headers"
    "composer"
    "java-latest-openjdk-headless"
    "lua-devel"
    "luarocks"
    "lua"
    "php-cli"
    "php-mbstring"
    "php-xml"
    "php-zip"
    "ruby-devel"
    "ruby"
)
install_dnf_packages "${lsp_packages[@]}" || true
install_dnf_packages "julia" || true

# Griffo tooling (lazygit, yazi, lazydocker).
griffo_tools=(
    "lazygit"
    "yazi"
)
install_dnf_packages "${griffo_tools[@]}" || true
if ! command -v lazydocker >/dev/null 2>&1; then
    install_dnf_packages "lazydocker" || {
        if command -v go >/dev/null 2>&1; then
            run_capture_on_fail "go install lazydocker" go install github.com/jesseduffield/lazydocker@latest || true
        fi
    }
fi

# Rust toolchain.
if [[ ! -f "$HOME/.cargo/env" ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>>"$ERROR_LOG_FILE" || true
fi

# Cursor CLI (best-effort; may require an interactive session).
if ! command -v cursor >/dev/null 2>&1; then
    curl -fsSL https://cursor.com/install | bash 2>>"$ERROR_LOG_FILE" || true
fi

# Ollama.
if ! command -v ollama >/dev/null 2>&1; then
    curl -fsSL https://ollama.com/install.sh | sh 2>>"$ERROR_LOG_FILE" || true
fi

# Build git-credential-libsecret from git contrib sources if not already present.
if [[ -d "/usr/share/doc/git/contrib/credential/libsecret" ]]; then
    credential_bin="/usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret"
    if [[ ! -x "$credential_bin" ]]; then
        install_dnf_packages "glib2-devel" || true
        run_capture_on_fail "build git-credential-libsecret" bash -c 'cd /usr/share/doc/git/contrib/credential/libsecret && sudo make' || true
    fi
fi

if command -v npm >/dev/null 2>&1; then
    sudo npm install -g bash-language-server pyright typescript-language-server yaml-language-server \
        --loglevel=error --no-update-notifier 2>>"$ERROR_LOG_FILE" || true
fi

install_dnf_packages "lua-language-server" || true

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
