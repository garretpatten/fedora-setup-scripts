#!/bin/bash

dnf_maintain_update() {
    sudo dnf makecache -y || true
}

dnf_maintain_upgrade() {
    sudo dnf upgrade -y || true
}

dnf_maintain_cleanup() {
    sudo dnf autoremove -y || true
}
