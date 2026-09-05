#!/usr/bin/env bash
# Shared install validation sections used by validate-installs*.sh.
# Sourcing scripts are expected to set PATH and source validate-common.sh first.

validate_preflight() {
    section 'Preflight'
    check_version curl curl --version
    check_version wget wget --version
    check_version git git --version
}

validate_cli_packages() {
    section 'Packages'
    check_version bat bat --version
    check_version eza eza --version
    check_version fd fd --version
    check_version fzf fzf --version
    check_version git git --version
    check_version htop htop --version
    check_version jq jq --version
    check_version ripgrep rg --version
    check_version tldr tldr --version
    check_version tree-sitter tree-sitter --version
    check_version pkg-config pkg-config --version
    check_rpm libsecret libsecret
    check_rpm libsecret-devel libsecret-devel
    check_rpm make make
    check_version gcc gcc --version
    check_version btop btop --version
    check_version fastfetch fastfetch --version
    check_version zoxide zoxide --version
    check_version flatpak flatpak --version
    check_version nmap nmap --version
    check_version exiftool exiftool -ver
    check_version openvpn openvpn --version
    check_version lazygit lazygit --version
    check_version lazydocker lazydocker --version
    check_version yazi yazi --version
    check_rpm ufw ufw
}

validate_media() {
    section 'Media'
    check_version brave brave-browser --version
    check_version vlc vlc --version
    if command -v ffmpeg >/dev/null 2>&1; then
        check_version ffmpeg ffmpeg -version
    elif command -v ffmpeg-free >/dev/null 2>&1; then
        check_version ffmpeg ffmpeg-free -version
    else
        fail ffmpeg 'ffmpeg or ffmpeg-free'
    fi
    check_flatpak spotify com.spotify.Client
}

validate_productivity() {
    section 'Productivity'
    check_version libreoffice libreoffice --version
    check_rpm keepassxc keepassxc
    check_command redshift redshift
    check_version flameshot flameshot --version
    check_flatpak zoom us.zoom.Zoom
    check_flatpak bruno com.usebruno.Bruno
    check_rpm gnome-tweaks gnome-tweaks
    check_rpm gnome-shell-extensions gnome-shell-extensions
    check_version google-chrome google-chrome-stable --version
    check_path etcher "$HOME/.local/bin/balenaEtcher.AppImage"
}

validate_nvm() {
    section 'nvm'
    check_path nvm "$HOME/.nvm/nvm.sh"
}

validate_dev() {
    section 'Dev'
    check_version node node --version
    check_version npm npm --version
    check_version python3 python3 --version
    check_version go go version
    check_version ruby ruby --version
    check_version rustc rustc --version
    check_version cargo cargo --version
    check_version php php --version
    check_version composer composer --version
    check_version java java --version
    if command -v julia >/dev/null 2>&1; then
        check_version julia julia --version
    else
        pass julia 'optional (not available in all Fedora releases)'
    fi
    check_version lua lua -e 'print(_VERSION)'
    check_version luarocks luarocks --version
    check_version gcc gcc --version
    check_version neovim nvim --version
    check_version gh gh --version
    check_version shellcheck shellcheck --version
    check_version docker docker --version
    check_version docker-compose 'docker compose version'
    if [[ "$(cat /proc/1/comm 2>/dev/null)" != "systemd" ]]; then
        pass docker-daemon 'optional (skipped without systemd PID 1)'
    elif docker info >/dev/null 2>&1; then
        pass docker-daemon 'docker info'
    else
        fail docker-daemon 'docker info'
    fi
    check_version lazygit lazygit --version
    check_version yazi yazi --version
    if command -v lazydocker >/dev/null 2>&1; then
        check_version lazydocker lazydocker --version
    else
        fail lazydocker 'lazydocker'
    fi
    if command -v semgrep >/dev/null 2>&1; then
        pass semgrep "$(version_of semgrep --version)"
    else
        fail semgrep 'semgrep'
    fi
    if command -v vue >/dev/null 2>&1; then
        pass vue-cli "$(version_of vue --version)"
    else
        fail vue-cli 'npm global @vue/cli'
    fi
    if command -v agent >/dev/null 2>&1; then
        pass cursor-agent "$(command -v agent)"
    elif command -v cursor-agent >/dev/null 2>&1; then
        pass cursor-agent "$(command -v cursor-agent)"
    else
        pass cursor-agent 'optional (best-effort install)'
    fi
    if command -v ollama >/dev/null 2>&1; then
        pass ollama "$(version_of ollama --version)"
    else
        pass ollama 'optional (best-effort install)'
    fi
    check_flatpak postman com.getpostman.Postman
    check_command bash-language-server bash-language-server
    check_command pyright pyright
    check_command typescript-language-server typescript-language-server
    check_command yaml-language-server yaml-language-server
    if command -v lua-language-server >/dev/null 2>&1; then
        check_version lua-language-server lua-language-server --version
    else
        pass lua-language-server 'optional'
    fi
}

validate_security_cli() {
    section 'Security'
    check_rpm ufw ufw
    check_version openvpn openvpn --version
    check_version nmap nmap --version
    check_version exiftool exiftool -ver
    check_path ufw-docker /usr/local/bin/ufw-docker
    check_flatpak zap org.zaproxy.ZAP
    check_command pass-cli pass-cli
    check_path hacking-payloads "$HOME/Hacking/PayloadsAllTheThings"
    check_path hacking-seclists "$HOME/Hacking/SecLists"
}

validate_security_desktop() {
    section 'Security (desktop)'
    if [[ "$(cat /proc/1/comm 2>/dev/null)" == "systemd" ]]; then
        check_rpm proton-vpn proton-vpn-gnome-desktop
    else
        pass proton-vpn 'optional (skipped without systemd PID 1)'
    fi
    if command -v proton-pass >/dev/null 2>&1 || rpm -q proton-pass >/dev/null 2>&1; then
        pass proton-pass 'proton-pass'
    else
        fail proton-pass 'proton-pass'
    fi
    check_flatpak signal org.signal.Signal
}

validate_pass_cli() {
    section 'pass-cli'
    check_version pass-cli pass-cli --version
}

validate_shell() {
    section 'Shell'
    check_version zsh zsh --version
    check_version tmux tmux -V
    if command -v oh-my-posh >/dev/null 2>&1; then
        check_version oh-my-posh oh-my-posh --version
    elif [[ -x "${HOME}/.local/bin/oh-my-posh" ]]; then
        pass oh-my-posh "$("${HOME}/.local/bin/oh-my-posh" --version 2>/dev/null | head -n1)"
    else
        fail oh-my-posh 'oh-my-posh (~/.local/bin/oh-my-posh)'
    fi
    check_rpm zsh-autosuggestions zsh-autosuggestions
    check_rpm zsh-syntax-highlighting zsh-syntax-highlighting
    check_rpm fontawesome-fonts fontawesome-fonts
    check_rpm fira-code-fonts fira-code-fonts
    check_path meslo-nerd-font /usr/share/fonts/meslo-nerd-font
    if command -v ghostty >/dev/null 2>&1; then
        pass ghostty "$(version_of ghostty --version)"
    else
        pass ghostty 'optional (not in all Fedora releases)'
    fi
}

validate_gnome() {
    section 'GNOME'
    check_rpm gnome-tweaks gnome-tweaks
    check_rpm gnome-shell-extensions gnome-shell-extensions
}
