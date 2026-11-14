#!/usr/bin/env bats
# Unit tests for src/scripts/lib/zsh-login.sh (HOME and zsh are sandboxed).
# shellcheck disable=SC2030,SC2031

setup() {
    load ../helpers/setup
    common_setup
    # shellcheck source=../../src/scripts/lib/zsh-login.sh
    source "$LIB_DIR/zsh-login.sh"

    # Fake zsh: records its arguments, exits with $FAKE_ZSH_EXIT.
    FAKE_ZSH="$SANDBOX/bin/zsh"
    mkdir -p "$SANDBOX/bin"
    cat >"$FAKE_ZSH" <<'SCRIPT'
#!/bin/bash
printf 'zsh %s\n' "$*" >>"$STUB_CALL_LOG"
exit "${FAKE_ZSH_EXIT:-0}"
SCRIPT
    chmod +x "$FAKE_ZSH"
}

teardown() {
    common_teardown
}

write_pass_cli_zshrc() {
    cat >"$HOME/.zshrc" <<'ZSHRC'
export EDITOR=nvim
GITHUB_TOKEN=$(pass-cli item view --vault Dev github-token)
export GITHUB_TOKEN
alias ll='ls -l'
ZSHRC
}

# --- ensure_zshrc_login_safe -------------------------------------------------

@test "ensure_zshrc_login_safe succeeds without a .zshrc" {
    run ensure_zshrc_login_safe
    assert_success
    assert_not_exists "$HOME/.zshrc"
}

@test "ensure_zshrc_login_safe leaves a .zshrc without pass-cli untouched" {
    echo "export EDITOR=nvim" >"$HOME/.zshrc"
    run ensure_zshrc_login_safe
    assert_success
    assert_equal "$(cat "$HOME/.zshrc")" "export EDITOR=nvim"
    assert_not_exists "$HOME/.zshrc.bak-setup-scripts"
}

@test "ensure_zshrc_login_safe comments out the pass-cli token lines and keeps a backup" {
    write_pass_cli_zshrc
    cp "$HOME/.zshrc" "$SANDBOX/original"
    run ensure_zshrc_login_safe
    assert_success
    assert_files_equal "$HOME/.zshrc.bak-setup-scripts" "$SANDBOX/original"
    run cat "$HOME/.zshrc"
    assert_line --index 0 "export EDITOR=nvim"
    # shellcheck disable=SC2016 # the literal $(...) text is what we expect
    assert_line --index 1 '# disabled-by-setup-scripts: GITHUB_TOKEN=$(pass-cli item view --vault Dev github-token)'
    assert_line --index 2 "# disabled-by-setup-scripts: export GITHUB_TOKEN"
    assert_line --index 3 "alias ll='ls -l'"
}

@test "ensure_zshrc_login_safe is idempotent" {
    write_pass_cli_zshrc
    ensure_zshrc_login_safe
    cp "$HOME/.zshrc" "$SANDBOX/after-first"
    run ensure_zshrc_login_safe
    assert_success
    assert_files_equal "$HOME/.zshrc" "$SANDBOX/after-first"
}

# --- zsh_login_safe ----------------------------------------------------------

@test "zsh_login_safe fails for an empty or non-executable zsh path" {
    run zsh_login_safe ""
    assert_failure
    run zsh_login_safe "$SANDBOX/missing-zsh"
    assert_failure
    assert_stub_calls
}

@test "zsh_login_safe runs an interactive zsh that exits immediately" {
    run zsh_login_safe "$FAKE_ZSH"
    assert_success
    assert_stub_calls "zsh -ic exit 0"
}

@test "zsh_login_safe fails when the zsh login check fails" {
    export FAKE_ZSH_EXIT=1
    run zsh_login_safe "$FAKE_ZSH"
    assert_failure
}

@test "zsh_login_safe fixes the .zshrc before starting zsh" {
    write_pass_cli_zshrc
    run zsh_login_safe "$FAKE_ZSH"
    assert_success
    assert_file_exists "$HOME/.zshrc.bak-setup-scripts"
}
