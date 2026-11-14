#!/bin/bash
# Shared setup for the bats unit tests. Load with: load ../helpers/setup

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
LIB_DIR="$REPO_ROOT/src/scripts/lib"
FIXTURES_DIR="$TESTS_DIR/fixtures"
export TESTS_DIR REPO_ROOT LIB_DIR FIXTURES_DIR

# bats-support, bats-assert and bats-file live in different places depending on
# how they were installed (bats-action, distro packages, manual clones).
BATS_LIB_PATH="${BATS_LIB_PATH:+$BATS_LIB_PATH:}/usr/lib:/usr/local/lib:/usr/lib/bats:/opt/homebrew/lib"
export BATS_LIB_PATH

common_setup() {
    # run --separate-stderr needs bats >= 1.5.0.
    bats_require_minimum_version 1.5.0
    bats_load_library bats-support
    bats_load_library bats-assert
    bats_load_library bats-file

    SANDBOX="$(mktemp -d "${BATS_TMPDIR:-/tmp}/fedora-setup-tests.XXXXXX")"
    export SANDBOX
    export HOME="$SANDBOX/home"
    export TEMP_DIR="$SANDBOX/tmp"
    export PROJECT_ROOT="$SANDBOX/project"
    mkdir -p "$HOME" "$TEMP_DIR" "$PROJECT_ROOT"
    unset XDG_CONFIG_HOME

    # Fake sudo/dnf/rpm/rpmkeys/curl/flatpak/install/sleep/loginctl shadow the
    # real ones, so nothing touches the network or the host system.
    export PATH="$TESTS_DIR/stubs:$PATH"
    export STUB_CALL_LOG="$SANDBOX/stub-calls.log"
    : >"$STUB_CALL_LOG"
    unset CURL_STUB_MODE CURL_STUB_BODY DNF_STUB_COPR_ENABLED DNF_STUB_FAIL_PACKAGES \
        DNF_STUB_FAIL_ALL RPM_STUB_KEYS RPM_STUB_INSTALLED RPM_STUB_FEDORA_RELEASE \
        FLATPAK_STUB_INSTALLED FLATPAK_STUB_FAIL FLATPAK_STUB_FAIL_ONCE \
        LOGINCTL_STUB_SESSIONS LOGINCTL_STUB_DESKTOP GIT_STUB_SUBMODULE_STATUS
}

common_teardown() {
    if [[ -n "${SANDBOX:-}" && -d "$SANDBOX" ]]; then
        rm -rf "$SANDBOX"
    fi
}

# Print the recorded stub calls (one per line).
stub_calls() {
    cat "$STUB_CALL_LOG"
}

# Assert the recorded stub calls equal the given lines, in order.
assert_stub_calls() {
    local expected=""
    if [[ $# -gt 0 ]]; then
        expected="$(printf '%s\n' "$@")"
    fi
    assert_equal "$(stub_calls)" "$expected"
}

# Assert no recorded stub call matches the given extended regex.
refute_stub_call() {
    if grep -Eq -- "$1" "$STUB_CALL_LOG"; then
        fail "unexpected stub call matching '$1':"$'\n'"$(stub_calls)"
    fi
}

# Assert some recorded stub call matches the given extended regex.
assert_stub_call() {
    if ! grep -Eq -- "$1" "$STUB_CALL_LOG"; then
        fail "no stub call matching '$1':"$'\n'"$(stub_calls)"
    fi
}
