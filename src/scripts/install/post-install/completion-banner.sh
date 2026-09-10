#!/bin/bash

art="$PROJECT_ROOT/src/assets/fedora.txt"
if [[ -f "$art" ]]; then
    echo
    echo "============================================================================"
    cat "$art"
    echo "============================================================================"
    echo
fi
echo "Setup completed."
