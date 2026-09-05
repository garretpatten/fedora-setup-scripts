#!/bin/bash

# shellcheck source=../../lib/dnf-maintain.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../lib/dnf-maintain.sh"

dnf_maintain_update
