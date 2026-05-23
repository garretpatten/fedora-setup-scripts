#!/bin/bash

# shellcheck source=../utils.sh
source "$(dirname "$0")/../utils.sh"

update_dnf_cache

defense_tools=(
    "ufw"
    "openvpn"
)
install_dnf_packages "${defense_tools[@]}"

fc=""
if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    fc="${VERSION_ID:-}"
fi
[[ -z "$fc" ]] && fc="$(rpm -E %fedora 2>/dev/null || echo "")"

protonvpn_release_rpm="$TEMP_DIR/protonvpn-stable-release.rpm"
[[ -z "$fc" ]] && fc="40"
protonvpn_repo_urls=(
    "https://repo.protonvpn.com/fedora-${fc}-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.4-1.noarch.rpm"
    "https://repo.protonvpn.com/fedora-${fc}-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.8-1.noarch.rpm"
)

protonvpn_repo_installed=0
for proton_url in "${protonvpn_repo_urls[@]}"; do
    [[ -z "$proton_url" ]] && continue
    rm -f "$protonvpn_release_rpm" 2>/dev/null || true
    if curl -fsSL --connect-timeout 30 --max-time 120 "$proton_url" -o "$protonvpn_release_rpm" 2>>"$ERROR_LOG_FILE" && [[ -s "$protonvpn_release_rpm" ]]; then
        sudo rpm -Uvh "$protonvpn_release_rpm" 2>>"$ERROR_LOG_FILE" || sudo rpm -ivh "$protonvpn_release_rpm" 2>>"$ERROR_LOG_FILE" || true
        protonvpn_repo_installed=1
        update_dnf_cache
        break
    fi
done

if [[ "$protonvpn_repo_installed" -eq 1 ]]; then
    if systemd_running_pid1; then
        protonvpn_packages=(
            "proton-vpn-gnome-desktop"
            "libappindicator-gtk3"
            "gnome-extensions-app"
            "gnome-shell-extension-appindicator"
        )
        install_dnf_packages "${protonvpn_packages[@]}"
    else
        echo "[fedora-setup] Skipping Proton VPN desktop stack (needs systemd PID 1; RPM post-install scripts)." || true
    fi
fi

# Proton Pass desktop RPM — canonical URLs live in version.json (see Proton support).
proton_pass_rpm="$TEMP_DIR/proton-pass.rpm"
proton_pass_version_json_urls=(
    "https://www.proton.me/download/PassDesktop/linux/x64/version.json"
    "https://proton.me/download/PassDesktop/linux/x64/version.json"
)

proton_pass_is_valid_rpm() {
    local candidate="$1"
    [[ -s "$candidate" ]] || return 1
    if command -v rpm >/dev/null 2>&1 && rpm -K "$candidate" >/dev/null 2>&1; then
        return 0
    fi
    if command -v rpm >/dev/null 2>&1 && rpm -qp "$candidate" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

proton_pass_resolve_latest_stable_rpm_url() {
    local json_path="$TEMP_DIR/proton-pass-version.json"
    local base_url rpm_url=""
    for base_url in "${proton_pass_version_json_urls[@]}"; do
        rm -f "$json_path" 2>/dev/null || true
        if ! curl -fsSL --connect-timeout 30 --max-time 120 --retry 3 --retry-delay 2 \
            -A "Mozilla/5.0 (X11; Linux x86_64)" \
            "$base_url" -o "$json_path" 2>>"$ERROR_LOG_FILE"; then
            continue
        fi
        [[ -s "$json_path" ]] || continue
        if command -v python3 >/dev/null 2>&1; then
            rpm_url=$(python3 -c '
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as fp:
    data = json.load(fp)
for rel in data.get("Releases", []):
    if rel.get("CategoryName") != "Stable":
        continue
    for item in rel.get("File", []):
        url = (item.get("Url") or "").strip()
        if not url.endswith(".rpm"):
            continue
        ident = item.get("Identifier") or ""
        if "RPM" in ident or "Fedora" in ident or ident.startswith(".rpm"):
            print(url)
            sys.exit(0)
sys.exit(1)
' "$json_path" 2>>"$ERROR_LOG_FILE") || rpm_url=""
            [[ -n "$rpm_url" ]] && printf '%s' "$rpm_url" && return 0
        fi
    done
    return 1
}

proton_pass_urls=()
if resolved=$(proton_pass_resolve_latest_stable_rpm_url); then
    proton_pass_urls+=("$resolved")
fi
proton_pass_urls+=(
    "https://proton.me/download/PassDesktop/linux/x64/ProtonPass.rpm"
    "https://www.proton.me/download/PassDesktop/linux/x64/ProtonPass.rpm"
)

proton_pass_downloaded=0
for proton_pass_url in "${proton_pass_urls[@]}"; do
    [[ -n "$proton_pass_url" ]] || continue
    rm -f "$proton_pass_rpm" 2>/dev/null || true
    if curl -fsSL --connect-timeout 30 --max-time 600 --retry 3 --retry-delay 2 --retry-all-errors \
        -A "Mozilla/5.0 (X11; Linux x86_64)" \
        "$proton_pass_url" -o "$proton_pass_rpm" 2>>"$ERROR_LOG_FILE" && proton_pass_is_valid_rpm "$proton_pass_rpm"; then
        proton_pass_downloaded=1
        break
    fi
done

if [[ "$proton_pass_downloaded" -eq 1 ]]; then
    sudo dnf install -y "$proton_pass_rpm" 2>>"$ERROR_LOG_FILE" || sudo rpm -ivh "$proton_pass_rpm" 2>>"$ERROR_LOG_FILE" || true
else
    echo "[fedora-setup] Proton Pass RPM download unresolved; install manually if needed." 2>/dev/null || true
fi

proton_pass_cli="$TEMP_DIR/proton-pass-cli"
proton_pass_cli_url=$(curl -s https://api.github.com/repos/protonpass/cli/releases/latest 2>>"$ERROR_LOG_FILE" | grep "browser_download_url.*linux-amd64" | cut -d '"' -f 4)
if [[ -n "$proton_pass_cli_url" ]]; then
    download_file_safe "$proton_pass_cli_url" "$proton_pass_cli"
    if [[ -f "$proton_pass_cli" ]] && [[ -s "$proton_pass_cli" ]]; then
        chmod +x "$proton_pass_cli" 2>>"$ERROR_LOG_FILE" || true
        sudo mv "$proton_pass_cli" /usr/local/bin/protonpass 2>>"$ERROR_LOG_FILE" || true
    fi
fi

if flatpak remote-info flathub >/dev/null 2>&1; then
    flatpak install -y flathub org.signal.Signal 2>>"$ERROR_LOG_FILE" || true
fi

dnf_security_tools=(
    "nmap"
    "perl-Image-ExifTool"
)
install_dnf_packages "${dnf_security_tools[@]}"

if flatpak remote-info flathub >/dev/null 2>&1; then
    flatpak install -y flathub org.zaproxy.ZAP 2>>"$ERROR_LOG_FILE" || true
fi

ensure_directory "$HOME/Hacking"

if [[ ! -d "$HOME/Hacking/PayloadsAllTheThings" ]]; then
    clone_repository_safe "https://github.com/swisskyrepo/PayloadsAllTheThings" "$HOME/Hacking/PayloadsAllTheThings"
fi

if [[ ! -d "$HOME/Hacking/SecLists" ]]; then
    clone_repository_safe "https://github.com/danielmiessler/SecLists" "$HOME/Hacking/SecLists"
fi
