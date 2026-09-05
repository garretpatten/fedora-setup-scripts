#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/env.sh
source "$DIR/../../lib/env.sh"
# shellcheck source=../../lib/dnf-repo-add.sh
source "$DIR/../../lib/dnf-repo-add.sh"

manifest="$DIR/manifest"
pids=()

while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// /}" ]] && continue

    (
        IFS='|' read -r kind _rest <<< "$line"
        case "$kind" in
            docker|brave)
                setup_repo_from_manifest_line "$kind"
                ;;
            nodesource)
                IFS='|' read -r _ node_major <<< "$line"
                setup_repo_from_manifest_line "$kind" "$node_major"
                ;;
            rpm-key)
                IFS='|' read -r _ key_url key_id <<< "$line"
                setup_repo_from_manifest_line "$kind" "$key_url" "$key_id"
                ;;
            repo-url)
                IFS='|' read -r _ repo_url repo_file <<< "$line"
                setup_repo_from_manifest_line "$kind" "$repo_url" "$repo_file"
                ;;
        esac
    ) &
    pids+=($!)
done < "$manifest"

for pid in "${pids[@]}"; do
    wait "$pid" || true
done
