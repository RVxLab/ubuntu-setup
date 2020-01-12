#!/bin/bash

set -e

function log {
    echo "[+] $1"
}

PREV_DIR=$(pwd)
REPO="https://github.com/RVxLab/ubuntu-setup.git"

if ! (which git && which zsh && which vim)
then
    echo "Please ensure git, zsh and vim are installed"
    exit 1
fi

log "Installing SpaceVim"
curl -sLf https://spacevim.org/install.sh | bash

if [[ ! -d "$HOME/.RVxLab" ]]
then
    log "Creating .RVxLab directory in $HOME"
    mkdir -p "$HOME/.RVxLab"
fi

log "Changing directory to $HOME/.RVxLab"
cd $HOME/.RVxLab

if [[ ! -d "$HOME/.RVxLab/ubuntu-setup" ]]
then
    git clone "$REPO"

    log "Running install script"
    bash "$HOME/.RVxLab/ubuntu-setup/run.sh"

    log "Done! To start using this, please change your shell to zsh"
else
    cd "$HOME/.RVxLab/ubuntu-setup"
    git pull

    log "Running install script"
    bash "$HOME/.RVxLab/ubuntu-setup/run.sh"

    log "Done!"
fi
