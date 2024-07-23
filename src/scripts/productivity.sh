#!/bin/bash

workingDirectory=$1

# Taskwarrior
if [[ ! -f "/usr/bin/task" ]]; then
    sudo dnf install task -y

    # Add custom themes
    mkdir -p "$HOME/.task/themes/"
    cp -r "$workingDirectory/src/dotfiles/taskwarrior/themes/" "$HOME/.task/themes/"

    # Handle first prompt (to create config file)
    echo "yes" | task

    # Update ~/.taskrc
    cat "$workingDirectory/src/dotfiles/taskwarrior/.taskrc-additions" >> "$HOME/.taskrc"

    # Add manual setup tasks
    task add Remove unneeded update commands from .zshrc project:setup priority:H
    task add Update .zshrc project:dev priority:H

    task add Install Notion project:PWAs priority:M
    task add Install Proton Drive project:PWAs priority:M
    task add Install Proton Mail project:PWAs priority:M
    task add Install Todoist project:PWAs priority:M
    task add Sign into and sync Brave project:setup priority:M
    task add Configure 1Password project:setup priority:M

    task add Take a snapshot of system project:setup priority:L
    task add Download needed files from Proton Drive project:setup priority:L
fi

# Timeshift
if [[ ! -f "/usr/bin/timeshift" ]]; then
    sudo dnf install timeshift -y
fi

# Todoist
if [[ ! -f "/usr/bin/todoist" ]]; then
    # TODO: Install Todoist
fi
