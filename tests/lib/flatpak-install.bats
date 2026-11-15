#!/usr/bin/env bats
# Unit tests for src/scripts/lib/flatpak-install.sh (flatpak and sleep stubbed).
# shellcheck disable=SC2030,SC2031

setup() {
    load ../helpers/setup
    common_setup
    # shellcheck source=../../src/scripts/lib/flatpak-install.sh
    source "$LIB_DIR/flatpak-install.sh"
}

teardown() {
    common_teardown
}

@test "install_flatpak_if_missing installs a missing app from flathub" {
    run install_flatpak_if_missing org.example.App
    assert_success
    assert_stub_calls \
        "flatpak list --app --columns=application" \
        "flatpak install -y flathub org.example.App"
}

@test "install_flatpak_if_missing skips an app that is already installed" {
    export FLATPAK_STUB_INSTALLED=$'org.other.App\norg.example.App'
    run install_flatpak_if_missing org.example.App
    assert_success
    assert_stub_calls "flatpak list --app --columns=application"
}

@test "install_flatpak_if_missing needs an exact app id match" {
    export FLATPAK_STUB_INSTALLED="org.example.App.Locale"
    run install_flatpak_if_missing org.example.App
    assert_success
    assert_stub_call '^flatpak install -y flathub org.example.App$'
}

@test "install_flatpak_if_missing retries once after 5 seconds" {
    export FLATPAK_STUB_FAIL_ONCE=org.example.App
    run install_flatpak_if_missing org.example.App
    assert_success
    assert_stub_calls \
        "flatpak list --app --columns=application" \
        "flatpak install -y flathub org.example.App" \
        "sleep 5" \
        "flatpak install -y flathub org.example.App"
}

@test "install_flatpak_if_missing is best-effort when both attempts fail" {
    export FLATPAK_STUB_FAIL=org.example.App
    run install_flatpak_if_missing org.example.App
    assert_success
    assert_equal "$(grep -c '^flatpak install' "$STUB_CALL_LOG")" 2
}

@test "install_flatpaks_from_file installs the first column of each entry" {
    printf '# apps\n\norg.one.App   # trailing note\n  \norg.two.App extra words\n' >"$SANDBOX/flatpaks"
    export FLATPAK_STUB_INSTALLED=org.two.App
    run install_flatpaks_from_file "$SANDBOX/flatpaks"
    assert_success
    assert_stub_calls \
        "flatpak list --app --columns=application" \
        "flatpak install -y flathub org.one.App" \
        "flatpak list --app --columns=application"
}

@test "install_flatpaks_from_file reads a last line without a trailing newline" {
    printf 'org.one.App' >"$SANDBOX/flatpaks"
    run install_flatpaks_from_file "$SANDBOX/flatpaks"
    assert_success
    assert_stub_call '^flatpak install -y flathub org.one.App$'
}
