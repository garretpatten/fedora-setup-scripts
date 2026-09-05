#!/usr/bin/env bash
# Shared config validation sections used by validate-config*.sh.
# Sourcing scripts are expected to source validate-common.sh first.

validate_config_dotfiles() {
    section 'Dotfiles'
    check_path dotfiles-nvim "$HOME/.config/nvim"
    check_path dotfiles-fastfetch "$HOME/.config/fastfetch"
    check_path dotfiles-btop "$HOME/.config/btop"
    check_path dotfiles-zellij "$HOME/.config/zellij"
    check_path dotfiles-tmux "$HOME/.config/tmux"
    check_path dotfiles-ghostty "$HOME/.config/ghostty"
    check_path dotfiles-oh-my-posh "$HOME/.config/oh-my-posh"
    check_path dotfiles-zsh "$HOME/.config/zsh"
    check_path zshrc "$HOME/.zshrc"
    check_path bashrc "$HOME/.bashrc"
    check_path tmux-conf "$HOME/.tmux.conf"
}

validate_config_home() {
    section 'Home layout'
    check_path screenshots-dir "$HOME/Pictures/Screenshots"
    check_path projects-personal "$HOME/Projects/personal"
    check_path hacking-dir "$HOME/Hacking"
}

validate_config_git() {
    section 'Git'
    credential_helper="/usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret"
    if [[ -x "$credential_helper" ]]; then
        check_path git-credential-libsecret "$credential_helper"
        if git config --global --get credential.helper 2>/dev/null | grep -Fq "$credential_helper"; then
            pass git-credential-helper 'ready for next commit (name and PAT at push)'
        else
            fail git-credential-helper "git config --global credential.helper $credential_helper"
        fi
    else
        if git config --global --get credential.helper 2>/dev/null | grep -q .; then
            pass git-credential-helper "$(git config --global --get credential.helper 2>/dev/null)"
        else
            fail git-credential-helper 'git credential.helper not set'
        fi
    fi
}

validate_config_ufw() {
    if ! command -v ufw >/dev/null 2>&1 || ! command -v iptables >/dev/null 2>&1; then
        pass ufw-active 'optional (ufw/iptables unavailable)'
        return 0
    fi
    if ! sudo iptables -t filter -S >/dev/null 2>&1; then
        pass ufw-active 'optional (iptables filter table not usable)'
        return 0
    fi
    if sudo ufw status 2>/dev/null | grep -qi 'Status: active'; then
        pass ufw-active 'ufw enabled'
    else
        fail ufw-active 'ufw status active'
    fi
}

validate_config_system_core() {
    check_path logind-lid /etc/systemd/logind.conf.d/50-lid.conf
    check_path sysctl-keepalive /etc/sysctl.d/99-tcp-keepalive.conf
    if command -v systemctl >/dev/null 2>&1 && systemctl is-enabled dnf-automatic.timer >/dev/null 2>&1; then
        pass dnf-automatic-timer 'enabled'
    else
        pass dnf-automatic-timer 'optional (systemd/timer not available)'
    fi
    if [[ ! -f /etc/gdm/custom.conf ]]; then
        pass gdm-no-guest 'optional (GDM not installed)'
    elif grep -qE '^AllowGuest=false' /etc/gdm/custom.conf 2>/dev/null; then
        pass gdm-no-guest /etc/gdm/custom.conf
    else
        fail gdm-no-guest 'AllowGuest=false in /etc/gdm/custom.conf'
    fi
}

validate_config_system() {
    section 'System'
    validate_config_ufw
    validate_config_system_core
}
