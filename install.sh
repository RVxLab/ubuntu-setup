#!/bin/bash

set -e

function log {
    echo "[+] $1"
}

REPO="https://github.com/RVxLab/ubuntu-setup.git"
CLONE_DIR="$HOME/.RVxLab/ubuntu-setup"

if ! (which git && which zsh && which vim) > /dev/null
then
    echo "Please ensure git, zsh and vim are installed"
    exit 1
fi

log "Installing SpaceVim"
curl -sLf https://spacevim.org/install.sh | bash

log "Installing Oh My Zsh"
wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash -xe -s - --unattended

if [[ ! -d "$HOME/.RVxLab" ]]
then
    log "Creating .RVxLab directory in $HOME"
    mkdir -p "$HOME/.RVxLab"
fi

if [[ ! -d "$HOME/.RVxLab/ubuntu-setup" ]]
then
    git clone "$REPO" "$CLONE_DIR"

    log "Running install script"
    bash -xe "$HOME/.RVxLab/ubuntu-setup/run.sh"

    log "Done! To start using this, please change your shell to zsh"
else
    cd "$HOME/.RVxLab/ubuntu-setup"
    git pull

    log "Running install script"
    bash -xe "$HOME/.RVxLab/ubuntu-setup/run.sh"

    log "Done!"
fi
