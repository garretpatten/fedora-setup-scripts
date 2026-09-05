#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/env.sh
source "$DIR/../lib/env.sh"
# shellcheck source=../lib/run.sh
source "$DIR/../lib/run.sh"
# shellcheck source=../lib/dnf-packages.sh
source "$DIR/../lib/dnf-packages.sh"
# shellcheck source=../lib/dnf-repo-add.sh
source "$DIR/../lib/dnf-repo-add.sh"
# shellcheck source=../lib/parallel.sh
source "$DIR/../lib/parallel.sh"

INSTALL_MODE="${1:-all}"
INSTALL_MODE="${INSTALL_MODE#-}"
INSTALL_MODE="${INSTALL_MODE#-}"

is_desktop() {
    [[ "$INSTALL_MODE" != cli ]]
}

PACKAGES=()
REPO_PIDS=()
ASYNC_PIDS=()
RPM_PIDS=()

REPO_SCRIPTS=(
    repos/setup.sh
)

ASYNC_SCRIPTS=(
    dev/nvm.sh
    dev/rustup.sh
    dev/cursor-cli.sh
    dev/ollama.sh
    dev/semgrep.sh
    dev/ruby-gems.sh
    dev/vue-cli.sh
    dev/language-servers.sh
    dev/go.sh
    shell/ghostty.sh
    shell/meslo-nerd-font.sh
    shell/oh-my-posh.sh
    apps/hacking-repos.sh
    apps/ufw-docker.sh
)

if is_desktop; then
    ASYNC_SCRIPTS+=(apps/flatpaks.sh)
fi

RPM_SCRIPTS=(
    apps/chrome.sh
    apps/etcher.sh
    apps/proton-pass.sh
)

echo "==> Installing base dnf packages..."
install_dnf_packages_from_file "$DIR/packages/base.packages"

echo "==> Installing shell dnf packages..."
install_dnf_packages_from_file "$DIR/packages/shell.packages"

if is_desktop; then
    echo "==> Installing media dnf packages..."
    install_dnf_packages_from_file "$DIR/packages/media.packages"

    echo "==> Installing desktop dnf packages..."
    install_dnf_packages_from_file "$DIR/packages/desktop.packages"

    echo "==> Installing productivity dnf packages..."
    install_dnf_packages_from_file "$DIR/packages/productivity.packages"
fi

echo "==> Setting up RPM repositories..."
for script in "${REPO_SCRIPTS[@]}"; do
    REPO_PIDS+=("$(parallel_run_best_effort "$DIR/$script")")
done
parallel_wait_pids_best_effort "repository setup" "${REPO_PIDS[@]}"

if is_desktop; then
    run_script "$DIR/apps/protonvpn-install.sh"
fi
sudo dnf makecache -y || true

echo "==> Reconciling shell dnf packages..."
install_dnf_packages_from_file "$DIR/packages/shell.packages"

if is_desktop; then
    echo "==> Reconciling media dnf packages..."
    install_dnf_packages_from_file "$DIR/packages/media.packages"

    echo "==> Reconciling desktop dnf packages..."
    install_dnf_packages_from_file "$DIR/packages/desktop.packages"
fi

echo "==> Installing dev and language packages..."
install_dnf_packages_from_file "$DIR/packages/lsp.packages"
install_dnf_packages_from_file "$DIR/packages/dev.packages"

echo "==> Installing extra dnf packages..."
install_dnf_packages_from_files optional \
    "$DIR/packages/griffo.packages" \
    "$DIR/packages/fastfetch.packages"

if is_desktop; then
    install_dnf_packages_from_file "$DIR/packages/optional-desktop.packages" optional
fi

PACKAGES=()
if is_desktop; then
    append_packages_from_file "$DIR/packages/third-party-desktop.packages" PACKAGES
fi
append_packages_from_file "$DIR/packages/third-party-cli.packages" PACKAGES
if ! install_collected_packages optional; then
    install_collected_packages_individually optional
fi

install_dnf_packages_from_file "$DIR/packages/lsp-optional.packages" optional

run_script "$DIR/dev/git-credential-libsecret.sh"

echo "==> Initializing asynchronous downloads..."
for script in "${ASYNC_SCRIPTS[@]}"; do
    ASYNC_PIDS+=("$(parallel_run_best_effort "$DIR/$script")")
done
parallel_wait_pids_best_effort "asynchronous tasks" "${ASYNC_PIDS[@]}"
echo "==> Asynchronous tasks completed."

if is_desktop; then
    echo "==> Installing RPM packages..."
    for script in "${RPM_SCRIPTS[@]}"; do
        RPM_PIDS+=("$(parallel_run_best_effort "$DIR/$script")")
    done
    parallel_wait_pids_best_effort "RPM package install" "${RPM_PIDS[@]}"
fi

run_script "$DIR/apps/pass-cli.sh"

run_script "$DIR/post-install/all.sh"
