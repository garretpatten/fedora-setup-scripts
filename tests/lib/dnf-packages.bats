#!/usr/bin/env bats
# Unit tests for src/scripts/lib/dnf-packages.sh (dnf stubbed, fixture lists).
# Each @test runs in its own subshell, so per-test variable changes are intentional.
# shellcheck disable=SC2030,SC2031,SC2034

setup() {
    load ../helpers/setup
    common_setup
    # shellcheck source=../../src/scripts/lib/dnf-packages.sh
    source "$LIB_DIR/dnf-packages.sh"
    PKGS="$FIXTURES_DIR/packages"
}

teardown() {
    common_teardown
}

# --- append_packages_from_file -----------------------------------------------

@test "append_packages_from_file appends to PACKAGES, skipping comments and blank lines" {
    PACKAGES=(existing)
    append_packages_from_file "$PKGS/core.packages"
    assert_equal "${PACKAGES[*]}" "existing git curl jq"
}

@test "append_packages_from_file appends to a named array" {
    PACKAGES=()
    EXTRA=(first)
    append_packages_from_file "$PKGS/media.packages" EXTRA
    assert_equal "${EXTRA[*]}" "first vlc ffmpeg-free"
    assert_equal "${#PACKAGES[@]}" 0
}

@test "append_packages_from_file leaves the array alone for a list with no packages" {
    PACKAGES=(existing)
    append_packages_from_file "$PKGS/empty.packages"
    assert_equal "${PACKAGES[*]}" "existing"
}

# --- install_dnf_packages_individually ---------------------------------------

@test "install_dnf_packages_individually installs each package and continues past failures" {
    export DNF_STUB_FAIL_PACKAGES="curl"
    run install_dnf_packages_individually "" git curl jq
    assert_success
    assert_stub_calls "sudo dnf install -y git" "sudo dnf install -y curl" "sudo dnf install -y jq"
}

@test "install_dnf_packages_individually behaves the same in optional mode" {
    export DNF_STUB_FAIL_PACKAGES="git"
    run install_dnf_packages_individually optional git jq
    assert_success
    assert_stub_calls "sudo dnf install -y git" "sudo dnf install -y jq"
}

# --- install_dnf_packages_from_file ------------------------------------------

@test "install_dnf_packages_from_file installs the whole list in one dnf call" {
    run install_dnf_packages_from_file "$PKGS/core.packages"
    assert_success
    assert_stub_calls "sudo dnf install -y git curl jq"
}

@test "install_dnf_packages_from_file falls back to one package at a time when the batch fails" {
    export DNF_STUB_FAIL_PACKAGES="curl"
    run install_dnf_packages_from_file "$PKGS/core.packages"
    assert_success
    assert_stub_calls \
        "sudo dnf install -y git curl jq" \
        "sudo dnf install -y git" \
        "sudo dnf install -y curl" \
        "sudo dnf install -y jq"
}

@test "install_dnf_packages_from_file optional mode also falls back and succeeds" {
    export DNF_STUB_FAIL_PACKAGES="jq"
    run install_dnf_packages_from_file "$PKGS/core.packages" optional
    assert_success
    assert_stub_calls \
        "sudo dnf install -y git curl jq" \
        "sudo dnf install -y git" \
        "sudo dnf install -y curl" \
        "sudo dnf install -y jq"
}

@test "install_dnf_packages_from_file does not call dnf for an empty list" {
    run install_dnf_packages_from_file "$PKGS/empty.packages"
    assert_success
    assert_stub_calls
}

# --- install_dnf_packages_from_files -----------------------------------------

@test "install_dnf_packages_from_files combines every list into one dnf call" {
    run install_dnf_packages_from_files "" "$PKGS/core.packages" "$PKGS/empty.packages" "$PKGS/media.packages"
    assert_success
    assert_stub_calls "sudo dnf install -y git curl jq vlc ffmpeg-free"
}

@test "install_dnf_packages_from_files retries per file, then per package, when the batch fails" {
    export DNF_STUB_FAIL_PACKAGES="curl"
    run install_dnf_packages_from_files "" "$PKGS/core.packages" "$PKGS/media.packages"
    assert_success
    assert_stub_calls \
        "sudo dnf install -y git curl jq vlc ffmpeg-free" \
        "sudo dnf install -y git curl jq" \
        "sudo dnf install -y git" \
        "sudo dnf install -y curl" \
        "sudo dnf install -y jq" \
        "sudo dnf install -y vlc ffmpeg-free"
}

@test "install_dnf_packages_from_files optional mode falls back to one package at a time" {
    export DNF_STUB_FAIL_PACKAGES="vlc"
    run install_dnf_packages_from_files optional "$PKGS/core.packages" "$PKGS/media.packages"
    assert_success
    assert_stub_calls \
        "sudo dnf install -y git curl jq vlc ffmpeg-free" \
        "sudo dnf install -y git" \
        "sudo dnf install -y curl" \
        "sudo dnf install -y jq" \
        "sudo dnf install -y vlc" \
        "sudo dnf install -y ffmpeg-free"
}

@test "install_dnf_packages_from_files does not call dnf when every list is empty" {
    run install_dnf_packages_from_files "" "$PKGS/empty.packages"
    assert_success
    assert_stub_calls
}

# --- install_collected_packages(_individually) -------------------------------

@test "install_collected_packages installs PACKAGES in one call" {
    PACKAGES=(git jq)
    run install_collected_packages
    assert_success
    assert_stub_calls "sudo dnf install -y git jq"
}

@test "install_collected_packages does nothing when PACKAGES is empty" {
    PACKAGES=()
    run install_collected_packages
    assert_success
    assert_stub_calls
}

@test "install_collected_packages returns failure when dnf fails" {
    PACKAGES=(git missing-pkg)
    export DNF_STUB_FAIL_PACKAGES="missing-pkg"
    run install_collected_packages
    assert_failure
    run install_collected_packages optional
    assert_failure
}

@test "install_collected_packages_individually installs each package and continues past failures" {
    PACKAGES=(git missing-pkg jq)
    export DNF_STUB_FAIL_PACKAGES="missing-pkg"
    run install_collected_packages_individually
    assert_success
    assert_stub_calls "sudo dnf install -y git" "sudo dnf install -y missing-pkg" "sudo dnf install -y jq"
}
