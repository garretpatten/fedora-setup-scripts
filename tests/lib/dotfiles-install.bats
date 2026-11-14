#!/usr/bin/env bats
# Unit tests for src/scripts/lib/dotfiles-install.sh.
# PROJECT_ROOT points at a sandbox copy of tests/fixtures/dotfiles, and HOME /
# XDG_CONFIG_HOME live in the sandbox.
# Literal "~" arguments are intentional: expand_home_path does the expansion.
# shellcheck disable=SC2030,SC2031,SC2088

setup() {
    load ../helpers/setup
    common_setup
    # shellcheck source=../../src/scripts/lib/dotfiles-install.sh
    source "$LIB_DIR/dotfiles-install.sh"
    mkdir -p "$PROJECT_ROOT/src"
    cp -R "$FIXTURES_DIR/dotfiles" "$PROJECT_ROOT/src/dotfiles"
}

teardown() {
    common_teardown
}

# --- expand_home_path --------------------------------------------------------

@test "expand_home_path expands ~ and ~/ to HOME" {
    run expand_home_path "~"
    assert_output "$HOME"
    run expand_home_path "~/.config/app/file"
    assert_output "$HOME/.config/app/file"
}

@test "expand_home_path leaves other paths unchanged" {
    run expand_home_path "/etc/hosts"
    assert_output "/etc/hosts"
    run expand_home_path "relative/path"
    assert_output "relative/path"
    run expand_home_path "~otheruser/file"
    assert_output "~otheruser/file"
}

# --- copy_dotfile_file -------------------------------------------------------

@test "copy_dotfile_file copies from src/dotfiles and creates parent directories" {
    run copy_dotfile_file home/.vimrc "~/deep/dir/.vimrc"
    assert_success
    assert_files_equal "$HOME/deep/dir/.vimrc" "$PROJECT_ROOT/src/dotfiles/home/.vimrc"
}

@test "copy_dotfile_file never overwrites an existing file" {
    echo "mine" >"$HOME/.vimrc"
    run copy_dotfile_file home/.vimrc "~/.vimrc"
    assert_success
    assert_equal "$(cat "$HOME/.vimrc")" "mine"
}

# --- link_dotfiles_xdg_config_dirs -------------------------------------------

@test "link_dotfiles_xdg_config_dirs symlinks each config/<app> under ~/.config" {
    run link_dotfiles_xdg_config_dirs
    assert_success
    assert_link_exists "$HOME/.config/nvim"
    assert_link_exists "$HOME/.config/tmux"
    assert_equal "$(readlink "$HOME/.config/nvim")" "$PROJECT_ROOT/src/dotfiles/config/nvim"
    assert_file_exists "$HOME/.config/tmux/tmux.conf"
}

@test "link_dotfiles_xdg_config_dirs honors XDG_CONFIG_HOME" {
    export XDG_CONFIG_HOME="$SANDBOX/xdg"
    run link_dotfiles_xdg_config_dirs
    assert_success
    assert_link_exists "$SANDBOX/xdg/nvim"
    assert_not_exists "$HOME/.config/nvim"
}

@test "link_dotfiles_xdg_config_dirs is idempotent" {
    link_dotfiles_xdg_config_dirs
    run link_dotfiles_xdg_config_dirs
    assert_success
    assert_equal "$(readlink "$HOME/.config/nvim")" "$PROJECT_ROOT/src/dotfiles/config/nvim"
    run compgen -G "$HOME/.config/*.dotfiles-bak-*"
    assert_failure
}

@test "link_dotfiles_xdg_config_dirs backs up an existing real directory" {
    mkdir -p "$HOME/.config/nvim"
    echo "old" >"$HOME/.config/nvim/init.lua"
    run --separate-stderr link_dotfiles_xdg_config_dirs
    assert_success
    assert_link_exists "$HOME/.config/nvim"
    # shellcheck disable=SC2154 # $stderr is set by run --separate-stderr
    [[ "$stderr" == *"$HOME/.config/nvim exists; moving to $HOME/.config/nvim.dotfiles-bak-"* ]]
    local backups=("$HOME"/.config/nvim.dotfiles-bak-*)
    assert_equal "$(cat "${backups[0]}/init.lua")" "old"
}

@test "link_dotfiles_xdg_config_dirs repoints a symlink that targets somewhere else" {
    mkdir -p "$HOME/.config" "$SANDBOX/elsewhere"
    ln -s "$SANDBOX/elsewhere" "$HOME/.config/nvim"
    run link_dotfiles_xdg_config_dirs
    assert_success
    assert_equal "$(readlink "$HOME/.config/nvim")" "$PROJECT_ROOT/src/dotfiles/config/nvim"
    assert_dir_exists "$SANDBOX/elsewhere"
}

@test "link_dotfiles_xdg_config_dirs succeeds without a config directory" {
    rm -rf "$PROJECT_ROOT/src/dotfiles/config"
    run link_dotfiles_xdg_config_dirs
    assert_success
    assert_not_exists "$HOME/.config"
}

# --- install_dotfiles_from_manifest ------------------------------------------

@test "install_dotfiles_from_manifest copies only file entries and skips comments" {
    cat >"$SANDBOX/manifest" <<'MANIFEST'
# comment line
   # indented comment

file home/.vimrc ~/.vimrc
link config/nvim ~/.config/nvim-link
file home/.vimrc ~/copies/vimrc
MANIFEST
    run install_dotfiles_from_manifest "$SANDBOX/manifest"
    assert_success
    assert_file_exists "$HOME/.vimrc"
    assert_file_exists "$HOME/copies/vimrc"
    assert_not_exists "$HOME/.config/nvim-link"
}

@test "install_dotfiles_from_manifest reads a last line without a trailing newline" {
    printf 'file home/.vimrc ~/.vimrc' >"$SANDBOX/manifest"
    run install_dotfiles_from_manifest "$SANDBOX/manifest"
    assert_success
    assert_file_exists "$HOME/.vimrc"
}
