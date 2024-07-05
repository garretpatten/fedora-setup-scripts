#!/bin/bash

workingDirectory=$(pwd)

bash "$workingDirectory/src/scripts/pre-install.sh"

# Home directory customization
bash "$workingDirectory/src/scripts/organizeHome.sh"

# CLI tools
bash "$workingDirectory/src/scripts/cli.sh"

# Browser
bash "$workingDirectory/src/scripts/web.sh"

# Streaming and video applications
bash "$workingDirectory/src/scripts/media.sh"

# Productivity programs
bash "$workingDirectory/src/scripts/productivity.sh" "$workingDirectory"

# Security and privacy utilities
bash "$workingDirectory/src/scripts/security.sh" "$workingDirectory"

# IDE setup
bash "$workingDirectory/src/scripts/ide.sh" "$workingDirectory"

# Dev tools
bash "$workingDirectory/src/scripts/dev.sh"

# Penetration testing tools and wordlists
bash "$workingDirectory/src/scripts/hacking.sh" "$workingDirectory"

zsh "$workingDirectory/src/scripts/shell.sh" "$workingDirectory"

bash "$workingDirectory/src/scripts/post-install.sh" "$workingDirectory"
