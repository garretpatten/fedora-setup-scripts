#!/usr/bin/env bats
# Unit tests for scripts/check-shellcheck.sh: which files it hands to ShellCheck.
# Each test builds a throwaway git repo with an origin/master ref and a feature
# commit on top, copies the script into it, and runs it with a fake shellcheck
# that records its arguments (plus one run with the real shellcheck).
# shellcheck disable=SC2030,SC2031

setup() {
    load ../helpers/setup
    common_setup

    FAKE_SHELLCHECK_DIR="$SANDBOX/fake-shellcheck"
    mkdir -p "$FAKE_SHELLCHECK_DIR"
    cat >"$FAKE_SHELLCHECK_DIR/shellcheck" <<'SCRIPT'
#!/bin/bash
printf 'shellcheck %s\n' "$*" >>"$STUB_CALL_LOG"
SCRIPT
    chmod +x "$FAKE_SHELLCHECK_DIR/shellcheck"

    REPO="$SANDBOX/repo"
    mkdir -p "$REPO/scripts"
    cp "$REPO_ROOT/scripts/check-shellcheck.sh" "$REPO/scripts/"
    git -C "$REPO" init -q -b master
    git -C "$REPO" config user.email tests@example.test
    git -C "$REPO" config user.name tests
    git -C "$REPO" config commit.gpgsign false
    mkdir -p "$REPO/src"
    cp "$FIXTURES_DIR/shellcheck/clean.sh" "$REPO/src/untouched.sh"
    echo "# readme" >"$REPO/README.md"
    git -C "$REPO" add -A
    git -C "$REPO" commit -q -m base
    # Pretend the base commit is what origin/master points at.
    git -C "$REPO" update-ref refs/remotes/origin/master HEAD
    git -C "$REPO" checkout -q -b feature
}

teardown() {
    common_teardown
}

commit_all() {
    git -C "$REPO" add -A
    git -C "$REPO" commit -q -m change
}

@test "check-shellcheck.sh exits 0 without running ShellCheck when no shell files changed" {
    echo "more" >>"$REPO/README.md"
    commit_all
    PATH="$FAKE_SHELLCHECK_DIR:$PATH" run "$REPO/scripts/check-shellcheck.sh"
    assert_success
    assert_output --partial "No changed shell files to check (base: origin/master)"
    assert_stub_calls
}

@test "check-shellcheck.sh checks only changed shell files, bats tests and stubs" {
    mkdir -p "$REPO/src/lib" "$REPO/tests/lib" "$REPO/tests/helpers" "$REPO/tests/stubs" "$REPO/docs"
    cp "$FIXTURES_DIR/shellcheck/clean.sh" "$REPO/src/lib/new.sh"
    cp "$FIXTURES_DIR/shellcheck/clean.sh" "$REPO/src/lib/thing.bash"
    cp "$FIXTURES_DIR/shellcheck/clean.sh" "$REPO/src/lib/thing.zsh"
    cp "$FIXTURES_DIR/shellcheck/clean.sh" "$REPO/tests/lib/new.bats"
    cp "$FIXTURES_DIR/shellcheck/clean.sh" "$REPO/tests/helpers/setup.bash"
    cp "$FIXTURES_DIR/shellcheck/clean.sh" "$REPO/tests/stubs/dnf"
    echo "notes" >"$REPO/docs/notes.md"
    echo "not shell" >"$REPO/src/lib/data.packages"
    commit_all
    PATH="$FAKE_SHELLCHECK_DIR:$PATH" run "$REPO/scripts/check-shellcheck.sh"
    assert_success
    assert_output --partial "ShellCheck -x (6 files, base: origin/master)"
    assert_stub_calls "shellcheck -x src/lib/new.sh src/lib/thing.bash src/lib/thing.zsh tests/helpers/setup.bash tests/lib/new.bats tests/stubs/dnf"
}

@test "check-shellcheck.sh skips deleted files and unchanged shell files" {
    git -C "$REPO" rm -q src/untouched.sh
    mkdir -p "$REPO/src"
    cp "$FIXTURES_DIR/shellcheck/clean.sh" "$REPO/src/changed.sh"
    commit_all
    PATH="$FAKE_SHELLCHECK_DIR:$PATH" run "$REPO/scripts/check-shellcheck.sh"
    assert_success
    assert_stub_calls "shellcheck -x src/changed.sh"
}

@test "check-shellcheck.sh passes a clean script and fails a dirty one with real ShellCheck" {
    command -v shellcheck >/dev/null 2>&1 || skip "shellcheck is not installed"
    cp "$FIXTURES_DIR/shellcheck/clean.sh" "$REPO/src/clean.sh"
    commit_all
    run "$REPO/scripts/check-shellcheck.sh"
    assert_success

    cp "$FIXTURES_DIR/shellcheck/dirty.sh.fixture" "$REPO/src/dirty.sh"
    commit_all
    run "$REPO/scripts/check-shellcheck.sh"
    assert_failure
    assert_output --partial "src/dirty.sh"
    assert_output --partial "SC2086"
}
