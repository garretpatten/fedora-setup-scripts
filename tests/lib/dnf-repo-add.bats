#!/usr/bin/env bats
# Unit tests for src/scripts/lib/dnf-repo-add.sh (rpm/rpmkeys/dnf/curl stubbed).
# Each @test runs in its own subshell, so per-test variable changes are intentional.
# shellcheck disable=SC2030,SC2031

setup() {
    load ../helpers/setup
    common_setup
    # shellcheck source=../../src/scripts/lib/dnf-repo-add.sh
    source "$LIB_DIR/dnf-repo-add.sh"
}

teardown() {
    common_teardown
}

# --- import_rpm_key_if_missing -----------------------------------------------

@test "import_rpm_key_if_missing skips the download when the key id is already imported" {
    export RPM_STUB_KEYS=$'gpg-pubkey-aaaa-1\ngpg-pubkey-DOCKER-2'
    run import_rpm_key_if_missing "https://example.test/gpg" "docker"
    assert_success
    refute_stub_call '^curl '
    refute_stub_call 'rpmkeys'
}

@test "import_rpm_key_if_missing downloads into TEMP_DIR and imports a missing key" {
    run import_rpm_key_if_missing "https://example.test/keys/vendor.gpg" "vendor"
    assert_success
    assert_file_exists "$TEMP_DIR/repo-key-vendor.gpg.asc"
    assert_stub_call "^curl -fsSL https://example.test/keys/vendor.gpg -o $TEMP_DIR/repo-key-vendor.gpg.asc$"
    assert_stub_call "^sudo rpmkeys --import $TEMP_DIR/repo-key-vendor.gpg.asc$"
}

@test "import_rpm_key_if_missing always imports when no key id is given" {
    export RPM_STUB_KEYS="gpg-pubkey-anything-1"
    run import_rpm_key_if_missing "https://example.test/key.asc" ""
    assert_success
    refute_stub_call '^rpm -q'
    assert_stub_call '^sudo rpmkeys --import '
}

@test "import_rpm_key_if_missing does not import when the download fails" {
    export CURL_STUB_MODE=fail
    run import_rpm_key_if_missing "https://example.test/key.asc" "vendor"
    assert_success
    assert_stub_call '^curl '
    refute_stub_call 'rpmkeys'
}

# --- install_repo_file_from_url ----------------------------------------------

@test "install_repo_file_from_url installs the downloaded file with mode 644" {
    local dest="$SANDBOX/etc/yum.repos.d/vendor.repo"
    export CURL_STUB_BODY="[vendor]"
    run install_repo_file_from_url "https://example.test/vendor.repo" "$dest"
    assert_success
    assert_file_exists "$dest"
    assert_equal "$(cat "$dest")" "[vendor]"
    assert_stub_call "^curl -fsSL https://example.test/vendor.repo -o $TEMP_DIR/repo-vendor.repo$"
    assert_stub_call "^sudo install -Dm644 $TEMP_DIR/repo-vendor.repo $dest$"
}

@test "install_repo_file_from_url is a no-op when the repo file already exists" {
    local dest="$SANDBOX/etc/yum.repos.d/vendor.repo"
    mkdir -p "$(dirname "$dest")"
    echo "existing" >"$dest"
    run install_repo_file_from_url "https://example.test/vendor.repo" "$dest"
    assert_success
    assert_equal "$(cat "$dest")" "existing"
    assert_stub_calls
}

@test "install_repo_file_from_url leaves no repo file when the download fails" {
    local dest="$SANDBOX/etc/yum.repos.d/vendor.repo"
    export CURL_STUB_MODE=fail
    run install_repo_file_from_url "https://example.test/vendor.repo" "$dest"
    assert_success
    assert_file_not_exists "$dest"
    refute_stub_call 'install -Dm644'
}

# --- setup_copr_repo ---------------------------------------------------------

@test "setup_copr_repo does nothing for an empty name" {
    run setup_copr_repo ""
    assert_success
    assert_stub_calls
}

@test "setup_copr_repo enables a COPR that is not enabled yet" {
    export DNF_STUB_COPR_ENABLED="someone/else"
    run setup_copr_repo "owner/project"
    assert_success
    assert_stub_calls "dnf copr list --enabled" "sudo dnf copr enable -y owner/project"
}

@test "setup_copr_repo skips a COPR that is already enabled" {
    export DNF_STUB_COPR_ENABLED=$'someone/else\nowner/project'
    run setup_copr_repo "owner/project"
    assert_success
    assert_stub_calls "dnf copr list --enabled"
}

@test "setup_copr_repo is best-effort when enabling fails" {
    export DNF_STUB_FAIL_ALL=1
    run setup_copr_repo "owner/project"
    assert_success
    assert_stub_call '^sudo dnf copr enable -y owner/project$'
}

# --- setup_rpmfusion_free_repo -----------------------------------------------

@test "setup_rpmfusion_free_repo skips when rpmfusion-free-release is installed" {
    export RPM_STUB_INSTALLED="rpmfusion-free-release"
    run setup_rpmfusion_free_repo
    assert_success
    assert_stub_calls "rpm -q rpmfusion-free-release"
}

@test "setup_rpmfusion_free_repo installs the release RPM for the running Fedora version" {
    export RPM_STUB_FEDORA_RELEASE=41
    run setup_rpmfusion_free_repo
    assert_success
    assert_stub_calls \
        "rpm -q rpmfusion-free-release" \
        "rpm -E %fedora" \
        "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-41.noarch.rpm"
}

@test "setup_rpmfusion_free_repo does nothing when the Fedora version is unknown" {
    run setup_rpmfusion_free_repo
    assert_success
    refute_stub_call 'dnf'
}

# --- vendor repos ------------------------------------------------------------

@test "setup_docker_repo imports the Docker key and installs docker-ce.repo" {
    [[ -f /etc/yum.repos.d/docker-ce.repo ]] && skip "host already has docker-ce.repo"
    run setup_docker_repo
    assert_success
    assert_stub_call '^curl -fsSL https://download.docker.com/linux/fedora/gpg '
    assert_stub_call '^sudo rpmkeys --import '
    assert_stub_call '^curl -fsSL https://download.docker.com/linux/fedora/docker-ce.repo '
    assert_stub_call " /etc/yum.repos.d/docker-ce.repo$"
}

@test "setup_brave_repo imports the Brave key and installs brave-browser.repo" {
    [[ -f /etc/yum.repos.d/brave-browser.repo ]] && skip "host already has brave-browser.repo"
    run setup_brave_repo
    assert_success
    assert_stub_call '^curl -fsSL https://brave-browser-rpm-release.s3.brave.com/brave-core.asc '
    assert_stub_call '^curl -fsSL https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo '
    assert_stub_call " /etc/yum.repos.d/brave-browser.repo$"
}

@test "setup_nodesource_repo downloads and runs the setup script for the requested major" {
    [[ -f /etc/yum.repos.d/nodesource-nsolid.repo ]] && skip "host already has nodesource-nsolid.repo"
    export CURL_STUB_BODY="echo nodesource-setup-ran >>\"\$STUB_CALL_LOG\""
    run setup_nodesource_repo 22
    assert_success
    assert_stub_call '^curl -fsSL https://rpm.nodesource.com/gpgkey/nodesource.gpg.key '
    assert_stub_call '^curl -fsSL https://rpm.nodesource.com/setup_22.x '
    assert_stub_call "^sudo bash $TEMP_DIR/nodesource_setup.sh$"
    assert_stub_call '^nodesource-setup-ran$'
}

@test "setup_nodesource_repo defaults to Node 24" {
    [[ -f /etc/yum.repos.d/nodesource-nsolid.repo ]] && skip "host already has nodesource-nsolid.repo"
    export CURL_STUB_BODY="true"
    run setup_nodesource_repo
    assert_success
    assert_stub_call '^curl -fsSL https://rpm.nodesource.com/setup_24.x '
}

@test "setup_nodesource_repo skips the setup script when the download fails" {
    [[ -f /etc/yum.repos.d/nodesource-nsolid.repo ]] && skip "host already has nodesource-nsolid.repo"
    export CURL_STUB_MODE=fail
    run setup_nodesource_repo
    assert_success
    refute_stub_call '^sudo bash '
}

# --- setup_repo_from_manifest_line -------------------------------------------

record_call() {
    printf '%s\n' "$*" >>"$STUB_CALL_LOG"
}

stub_repo_helpers() {
    setup_docker_repo() { record_call setup_docker_repo; }
    setup_brave_repo() { record_call setup_brave_repo; }
    setup_nodesource_repo() { record_call setup_nodesource_repo "$@"; }
    setup_copr_repo() { record_call setup_copr_repo "$@"; }
    setup_rpmfusion_free_repo() { record_call setup_rpmfusion_free_repo; }
    import_rpm_key_if_missing() { record_call import_rpm_key_if_missing "$@"; }
    install_repo_file_from_url() { record_call install_repo_file_from_url "$@"; }
}

@test "setup_repo_from_manifest_line dispatches each kind to its helper" {
    stub_repo_helpers
    setup_repo_from_manifest_line docker
    setup_repo_from_manifest_line brave
    setup_repo_from_manifest_line nodesource 22
    setup_repo_from_manifest_line copr owner/project
    setup_repo_from_manifest_line rpmfusion-free
    setup_repo_from_manifest_line rpm-key https://example.test/key.asc keyid
    setup_repo_from_manifest_line repo-url https://example.test/x.repo /etc/yum.repos.d/x.repo
    assert_stub_calls \
        "setup_docker_repo" \
        "setup_brave_repo" \
        "setup_nodesource_repo 22" \
        "setup_copr_repo owner/project" \
        "setup_rpmfusion_free_repo" \
        "import_rpm_key_if_missing https://example.test/key.asc keyid" \
        "install_repo_file_from_url https://example.test/x.repo /etc/yum.repos.d/x.repo"
}

@test "setup_repo_from_manifest_line ignores unknown kinds" {
    stub_repo_helpers
    run setup_repo_from_manifest_line mystery arg
    assert_success
    assert_stub_calls
}
