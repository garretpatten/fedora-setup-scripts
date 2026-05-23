#!/bin/bash

# Shell dotfiles and terminal configs from the submodule (~/.dotfiles_path, modular tmux tree).

# shellcheck source=../utils.sh
source "$(dirname "$0")/../utils.sh"

dotfiles_root="$PROJECT_ROOT/src/dotfiles"
dotfiles_home_root="$dotfiles_root/home"

if [[ -d "$dotfiles_root/config" ]]; then
    copy_directory_safe "$dotfiles_root/config/ghostty" "$HOME/.config/ghostty"
    copy_directory_safe "$dotfiles_root/config/oh-my-posh" "$HOME/.config/oh-my-posh"
    copy_directory_safe "$dotfiles_root/config/tmux" "$HOME/.config/tmux"
fi

if [[ -d "$dotfiles_home_root" ]]; then
    copy_file_safe "$dotfiles_home_root/.tmux.conf" "$HOME/.tmux.conf"
    copy_file_safe "$dotfiles_home_root/.zshrc" "$HOME/.zshrc"
    copy_file_safe "$dotfiles_home_root/.bashrc" "$HOME/.bashrc"
fi

# ~/.dotfiles_path caches the submodule checkout so home/.zshrc can resolve DOTFILES/home/zsh (fedora.zsh on Fedora).

if [[ -d "$dotfiles_home_root/zsh" ]]; then
    if [[ ! -f "$HOME/.dotfiles_path" ]]; then
        printf '%s\n' "$dotfiles_root" >"$HOME/.dotfiles_path" 2>>"$ERROR_LOG_FILE" || true
    else
        existing_root=""
        IFS= read -r existing_root <"$HOME/.dotfiles_path" || true
        if [[ -z "$existing_root" ]] || [[ ! -d "$existing_root/home/zsh" ]]; then
            printf '%s\n' "$dotfiles_root" >"$HOME/.dotfiles_path" 2>>"$ERROR_LOG_FILE" || true
        fi
    fi
fi

zsh_path=""
zsh_path="$(command -v zsh 2>/dev/null || true)"
if [[ -n "$zsh_path" ]] && [[ "$SHELL" != "$zsh_path" ]]; then
    chsh -s "$zsh_path" 2>/dev/null || true
fi
