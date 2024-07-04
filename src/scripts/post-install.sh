#!/bin/bash

# Final system update
sudo pacman -Syu --noconfirm && yay -Yc --noconfirm

workingDirectory=$1

printf "\n\n============================================================================\n\n"

cat "$workingDirectory/src/assets/wolf.txt"

printf "\n\n============================================================================\n\n"

printf \
"Run the following to enable Docker daemon on startup:
    sudo systemctl start docker.service
    sudo systemctl enable docker.service
    sudo usermod -aG docker %s
    newgrp docker\r" "$USER"

printf "\n\n============================================================================\n\n\r"

printf "Cheers -- system setup is now complete.\n\r"
printf "Log out and log back in to complete shell change.\n"
printf "When logged back in, restart shell to complete powerlevel10k configuration.\n"
