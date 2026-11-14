#!/usr/bin/env bats
# Unit tests for src/scripts/lib/run.sh and src/scripts/lib/env.sh.
# shellcheck disable=SC2030,SC2031

setup() {
    load ../helpers/setup
    common_setup
    # shellcheck source=../../src/scripts/lib/run.sh
    source "$LIB_DIR/run.sh"
}

teardown() {
    common_teardown
}

@test "ensure_temp_dir creates an existing TEMP_DIR path" {
    export TEMP_DIR="$SANDBOX/nested/tmp"
    ensure_temp_dir
    assert_dir_exists "$SANDBOX/nested/tmp"
    assert_equal "$TEMP_DIR" "$SANDBOX/nested/tmp"
}

@test "ensure_temp_dir defaults TEMP_DIR to /tmp/fedora-setup-<pid>" {
    unset TEMP_DIR
    ensure_temp_dir
    assert_equal "$TEMP_DIR" "/tmp/fedora-setup-$$"
    assert_dir_exists "$TEMP_DIR"
    rmdir "$TEMP_DIR"
}

@test "run_script forwards extra arguments" {
    run run_script "$FIXTURES_DIR/record-args.sh" cli --flag "two words"
    assert_success
    assert_stub_calls "record-args cli --flag two words"
}

@test "run_script swallows a failing script" {
    export FIXTURE_EXIT=3
    run run_script "$FIXTURES_DIR/record-args.sh"
    assert_success
    assert_stub_calls "record-args "
}

@test "run_script creates TEMP_DIR before running the script" {
    export TEMP_DIR="$SANDBOX/fresh-tmp"
    run run_script "$FIXTURES_DIR/record-args.sh"
    assert_success
    assert_dir_exists "$SANDBOX/fresh-tmp"
}

@test "run_script sources env.sh when PROJECT_ROOT is unset" {
    unset PROJECT_ROOT
    export TEMP_DIR="$SANDBOX/tmp"
    cat >"$SANDBOX/print-root.sh" <<'SCRIPT'
#!/bin/bash
printf 'root=%s\n' "$PROJECT_ROOT" >>"$STUB_CALL_LOG"
SCRIPT
    run_script "$SANDBOX/print-root.sh"
    assert_stub_calls "root=$REPO_ROOT"
    # env.sh resets TEMP_DIR to /tmp/fedora-setup-<pid>; clean it up.
    assert_equal "$TEMP_DIR" "/tmp/fedora-setup-$$"
    rmdir "$TEMP_DIR"
}

@test "env.sh exports PROJECT_ROOT as the repository root and creates TEMP_DIR" {
    run bash -c 'source "$1"; printf "%s\n%s\n" "$PROJECT_ROOT" "$TEMP_DIR"; [[ -d "$TEMP_DIR" ]] && rmdir "$TEMP_DIR"' _ "$LIB_DIR/env.sh"
    assert_success
    assert_line --index 0 "$REPO_ROOT"
    assert_line --index 1 --regexp '^/tmp/fedora-setup-[0-9]+$'
}
