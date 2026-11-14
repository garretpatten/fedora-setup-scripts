#!/usr/bin/env bats
# Unit tests for src/scripts/lib/dnf-repos.sh (dnf stubbed).
# shellcheck disable=SC2030,SC2031

setup() {
    load ../helpers/setup
    common_setup
    # shellcheck source=../../src/scripts/lib/dnf-repos.sh
    source "$LIB_DIR/dnf-repos.sh"
}

teardown() {
    common_teardown
}

@test "enable_copr_if_available enables a COPR that is not enabled" {
    run enable_copr_if_available "owner/project"
    assert_success
    assert_stub_calls "dnf copr list --enabled" "sudo dnf copr enable -y owner/project"
}

@test "enable_copr_if_available skips an already-enabled COPR" {
    export DNF_STUB_COPR_ENABLED="owner/project"
    run enable_copr_if_available "owner/project"
    assert_success
    assert_stub_calls "dnf copr list --enabled"
}

@test "enable_copr_if_available needs an exact match, not a prefix" {
    export DNF_STUB_COPR_ENABLED="owner/project-extra"
    run enable_copr_if_available "owner/project"
    assert_success
    assert_stub_call '^sudo dnf copr enable -y owner/project$'
}

@test "enable_copr_if_available is best-effort when dnf fails" {
    export DNF_STUB_FAIL_ALL=1
    run enable_copr_if_available "owner/project"
    assert_success
}
