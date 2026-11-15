#!/usr/bin/env bats
# Unit tests for src/scripts/lib/gnome-session.sh (loginctl stubbed).
# shellcheck disable=SC2030,SC2031

setup() {
    load ../helpers/setup
    common_setup
    # shellcheck source=../../src/scripts/lib/gnome-session.sh
    source "$LIB_DIR/gnome-session.sh"
    unset XDG_CURRENT_DESKTOP DESKTOP_SESSION GNOME_SHELL_SESSION_MODE
    export USER=tester
}

teardown() {
    common_teardown
}

@test "gnome_session_active detects GNOME in XDG_CURRENT_DESKTOP (any case, any position)" {
    local value
    for value in GNOME gnome "ubuntu:GNOME" "GNOME-Classic:GNOME"; do
        XDG_CURRENT_DESKTOP="$value" run gnome_session_active
        assert_success
    done
}

@test "gnome_session_active accepts the known GNOME DESKTOP_SESSION names" {
    local value
    for value in gnome gnome-xorg gnome-wayland gnome-classic fedora fedora-wayland; do
        DESKTOP_SESSION="$value" run gnome_session_active
        assert_success
    done
}

@test "gnome_session_active trusts GNOME_SHELL_SESSION_MODE" {
    GNOME_SHELL_SESSION_MODE=user run gnome_session_active
    assert_success
    assert_stub_calls
}

@test "gnome_session_active is false for another desktop with no GNOME login session" {
    export XDG_CURRENT_DESKTOP=KDE DESKTOP_SESSION=plasma
    run gnome_session_active
    assert_failure
    assert_stub_calls "loginctl list-sessions --no-legend"
}

@test "gnome_session_active finds a GNOME session for the current user via loginctl" {
    export LOGINCTL_STUB_SESSIONS=$'  c1 1000 tester seat0 tty2'
    export LOGINCTL_STUB_DESKTOP=GNOME
    run gnome_session_active
    assert_success
    assert_stub_call '^loginctl show-session c1 -p Desktop --value$'
}

@test "gnome_session_active ignores other users' sessions" {
    export LOGINCTL_STUB_SESSIONS=$'  c1 1001 someone seat0 tty2'
    export LOGINCTL_STUB_DESKTOP=GNOME
    run gnome_session_active
    assert_failure
    refute_stub_call 'show-session'
}

@test "gnome_session_active is false when the user's session is not GNOME" {
    export LOGINCTL_STUB_SESSIONS=$'  c1 1000 tester seat0 tty2'
    export LOGINCTL_STUB_DESKTOP=KDE
    run gnome_session_active
    assert_failure
}
