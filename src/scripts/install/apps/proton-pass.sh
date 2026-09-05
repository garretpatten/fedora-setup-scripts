#!/bin/bash
# Proton Pass desktop RPM.

if command -v proton-pass >/dev/null 2>&1 || rpm -q proton-pass >/dev/null 2>&1; then
    exit 0
fi

proton_pass_rpm="$TEMP_DIR/proton-pass.rpm"
proton_pass_version_json_urls=(
    "https://www.proton.me/download/PassDesktop/linux/x64/version.json"
    "https://proton.me/download/PassDesktop/linux/x64/version.json"
)

proton_pass_is_valid_rpm() {
    local candidate="$1"
    [[ -s "$candidate" ]] || return 1
    if rpm -K "$candidate" >/dev/null 2>&1 || rpm -qp "$candidate" >/dev/null 2>&1; then
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
            "$base_url" -o "$json_path" 2>/dev/null; then
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
' "$json_path" 2>/dev/null) || rpm_url=""
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
        "$proton_pass_url" -o "$proton_pass_rpm" 2>/dev/null && proton_pass_is_valid_rpm "$proton_pass_rpm"; then
        proton_pass_downloaded=1
        break
    fi
done

if [[ "$proton_pass_downloaded" -eq 1 ]]; then
    sudo dnf install -y "$proton_pass_rpm" || sudo rpm -ivh --nogpgcheck "$proton_pass_rpm" || true
fi
