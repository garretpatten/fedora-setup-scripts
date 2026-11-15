#!/usr/bin/env bats
# Unit tests for src/scripts/lib/dnf-maintain.sh (dnf stubbed).
# shellcheck disable=SC2030,SC2031

setup() {
    load ../helpers/setup
    common_setup
    # shellcheck source=../../src/scripts/lib/dnf-maintain.sh
    source "$LIB_DIR/dnf-maintain.sh"
}

teardown() {
    common_teardown
}

@test "dnf_maintain_update refreshes the metadata cache" {
    run dnf_maintain_update
    assert_success
    assert_stub_calls "sudo dnf makecache -y"
}

@test "dnf_maintain_upgrade upgrades all packages" {
    run dnf_maintain_upgrade
    assert_success
    assert_stub_calls "sudo dnf upgrade -y"
}

@test "dnf_maintain_cleanup autoremoves unused packages" {
    run dnf_maintain_cleanup
    assert_success
    assert_stub_calls "sudo dnf autoremove -y"
}

@test "update, upgrade, cleanup run dnf subcommands in that order" {
    dnf_maintain_update
    dnf_maintain_upgrade
    dnf_maintain_cleanup
    assert_stub_calls "sudo dnf makecache -y" "sudo dnf upgrade -y" "sudo dnf autoremove -y"
}

@test "maintenance helpers are best-effort when dnf fails" {
    export DNF_STUB_FAIL_ALL=1
    run dnf_maintain_update
    assert_success
    run dnf_maintain_upgrade
    assert_success
    run dnf_maintain_cleanup
    assert_success
}
