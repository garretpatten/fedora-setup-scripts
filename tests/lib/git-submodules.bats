#!/usr/bin/env bats
# Unit tests for src/scripts/lib/git-submodules.sh (git stubbed).
# shellcheck disable=SC2030,SC2031

setup() {
    load ../helpers/setup
    common_setup
    export PATH="$TESTS_DIR/stubs/submodule-git:$PATH"
    # shellcheck source=../../src/scripts/lib/git-submodules.sh
    source "$LIB_DIR/git-submodules.sh"
    mkdir -p "$PROJECT_ROOT/.git"
}

teardown() {
    common_teardown
}

@test "ensure_submodules_synced fails when no project root is known" {
    unset PROJECT_ROOT
    run --separate-stderr ensure_submodules_synced
    assert_failure 1
    # shellcheck disable=SC2154 # $stderr is set by run --separate-stderr
    assert_equal "$stderr" "ERROR: PROJECT_ROOT is not set; cannot sync submodules."
    assert_stub_calls
}

@test "ensure_submodules_synced skips a directory that is not a git checkout" {
    mkdir -p "$SANDBOX/plain"
    run --separate-stderr ensure_submodules_synced "$SANDBOX/plain"
    assert_success
    assert_equal "$stderr" "WARNING: Not a git repository; skipping submodule sync."
    assert_stub_calls
}

@test "ensure_submodules_synced initializes uninitialized submodules" {
    export GIT_STUB_SUBMODULE_STATUS="-ea0067ccac7436678a389e16052820afce59ee16 src/dotfiles"
    run ensure_submodules_synced "$PROJECT_ROOT"
    assert_success
    assert_output "==> Initializing submodules..."
    assert_stub_calls "git submodule status" "git submodule update --init --recursive"
}

@test "ensure_submodules_synced updates already-initialized submodules" {
    export GIT_STUB_SUBMODULE_STATUS=" ea0067ccac7436678a389e16052820afce59ee16 src/dotfiles (heads/master)"
    run ensure_submodules_synced "$PROJECT_ROOT"
    assert_success
    assert_output "==> Updating submodules..."
    assert_stub_calls "git submodule status" "git submodule update --recursive"
}

@test "ensure_submodules_synced defaults to PROJECT_ROOT and keeps the caller's directory" {
    cd "$SANDBOX"
    # shellcheck disable=SC2119 # calling with no argument is the point
    ensure_submodules_synced >/dev/null
    assert_equal "$PWD" "$SANDBOX"
    assert_stub_call '^git submodule update --recursive$'
}
