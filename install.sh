#!/bin/bash

set -e

PROGRESS_FILE="/var/tmp/.ubuntu-setup-progress"
IS_MINT=0
INSTALL_DOCKER=0
INSTALL_NVM=0
INSTALL_DAVFS=0
SHOULD_SIGN_OUT=0

while (( "$#" ))
do
    case "$1" in
        --with-docker)
            INSTALL_DOCKER=0
            shift
            ;;
        --with-nvm)
            INSTALL_NVM=1
            shift
            ;;
        --with-davfs)
            INSTALL_DAVFS=0
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [[ $(lsb_release -is) == "LinuxMint" ]]
then
    IS_MINT=1
fi

# Output shorthand
function log {
    local DATE
    DATE=$(date +"%Y-%m-%d %H:%M:%S")

    echo "[$DATE]: $1"
}

# Get packages to install with apt
function getPackagesList {
    local PACKAGES=("vim" "zsh" "git")

    if [[ $INSTALL_DOCKER -eq 1 ]]
    then
        PACKAGES+=("docker-ce" "docker-ce-cli" "containerd.io")
    fi

    if [[ $INSTALL_DAVFS -eq 1 ]]
    then
        PACKAGES+=("davfs2")
    fi

    echo "${PACKAGES[*]}"
}

# Get Ubuntu/Debian distro version
function getDistro {
    lsb_release -cs
}

# Get Ubuntu equivilant for Mint distros
function getUbuntuEquivForMint {
    VERSION=$(lsb_release -rs)

    if [[ "$VERSION" == "19*" ]]
    then
        echo "bionic"
    fi
}

# Install docker ppa
function installDockerPPA {
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    if ! sudo apt-key fingerprint 0EBFCD88
    then
        return 1
    fi

    if [[ $IS_MINT -eq 1 ]]
    then
        DISTRO=$(getUbuntuEquivForMint)
    else
        DISTRO=$(getDistro)
    fi

    sudo add-apt-repository -yqq "deb [arch=amd64] https://download.docker.com/linux/ubuntu $DISTRO stable"
    sudo apt-get -yqq update
}

# Install nvm
function installNvm {
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
}

# Install oh my zsh
function installOhMyZsh {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]
    then
        curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash -s - --unattended
    fi
}

# Get .zshrc contents
function getZshrc {
    local ZSH_PLUGINS
    ZSH_PLUGINS=(git)

    if [[ $INSTALL_NVM -eq 1 ]]
    then
        ZSH_PLUGINS+=(nvm)
    fi

    local ZSHRC
    ZSHRC=$(cat <<EOF
ZSH_THEME="agnoster"
HIST_STAMPS="yyyy-mm-dd"
ZSH_CUSTOM="\$HOME/scripts"

plugins=(${ZSH_PLUGINS[*]})

export ZSH="\$HOME/.oh-my-zsh"
source \$ZSH/oh-my-zsh.sh
EOF
)

    if [[ $INSTALL_NVM -eq 1 ]]
    then
        ZSHRC=$(cat <<EOF
$ZSHRC

export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
EOF
)
    fi

    echo "$ZSHRC"
}

# Set progress
function setProgress {
    CURRENT_PROGRESS=$1
    echo "$1" > "$PROGRESS_FILE"
}

# Get progress
function getProgress {
    if [[ ! -f "$PROGRESS_FILE" ]]
    then
        echo "0"
    else
        local PROGRESS
        PROGRESS=$(cat "$PROGRESS_FILE")

        if [[ -z $PROGRESS ]]
        then
            echo "0"
        else
            echo "$PROGRESS"
        fi
    fi
}

# Change shell to zsh
function setShellZsh {
    sudo chsh -s "$(command -v zsh)" "$USER"
}

# Set .zshrc
function setZshrc {
    getZshrc > "$HOME/.zshrc"
}

# Install prerequisites
function installPrerequisites {
    sudo apt-get -yqq update
    sudo apt-get -yqq install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
}

# Install packages
function installPackages {
    # shellcheck disable=SC2046
    sudo apt-get install -yqq $(getPackagesList)
}

# Prompt sign out
function setShouldSignOut {
    SHOULD_SIGN_OUT=1
}

# Setup user groups
function setupUserGroup {
    if [[ $INSTALL_DOCKER -eq 1 ]]
    then
        sudo groupadd docker
        sudo usermod -aG docker "$USER"
    fi

    if [[ $INSTALL_DAVFS -eq 1 ]]
    then
        sudo usermod -aG davfs2 "$USER"
    fi
}

CURRENT_PROGRESS=$(getProgress)

# Let's roll!
# Steps:
# 0 = Fresh run
# 1 = Prerequisites installed
# 2 = Docker PPA
# 3 = Install packages
# 4 = Change shell to zsh
# 5 = Set up user groups
# 6 = Install oh my zsh
# 7 = Install nvm

# Kick off
if [[ $CURRENT_PROGRESS -eq 0 ]]
then
    log "Let's set up stuff!"
    setProgress 1
fi

# Install the prerequisites to get going
if [[ $CURRENT_PROGRESS -eq 1 ]]
then
    log "Installing prerequisites"
    installPrerequisites
    setProgress 2
fi

# Install the Docker PPA
if [[ $CURRENT_PROGRESS -eq 2 ]]
then
    if [[ $INSTALL_DOCKER -eq 1 ]]
    then
        log "Adding Docker PPA"
        installDockerPPA
    fi

    setProgress 3
fi

# Install all packages
if [[ $CURRENT_PROGRESS -eq 3 ]]
then
    log "Installing packages"
    installPackages
    setProgress 4
fi

# Set shell to zsh
if [[ $CURRENT_PROGRESS -eq 4 ]]
then
    log "Setting shell to zsh"
    setShellZsh
    setShouldSignOut
    setProgress 5
fi

# Set up user groups
if [[ $CURRENT_PROGRESS -eq 5 ]]
then
    log "Setting up user groups"
    setupUserGroup
    setShouldSignOut
    setProgress 6
fi

# Set up ohmyzsh
if [[ $CURRENT_PROGRESS -eq 6 ]]
then
    log "Installing oh my zsh"
    installOhMyZsh
    setZshrc
    setProgress 7
fi

# Set up nvm
if [[ $INSTALL_NVM -eq 1 && $CURRENT_PROGRESS -eq 7 ]]
then
    log "Installing nvm"
    installNvm
    setProgress 8
fi

if [[ $SHOULD_SIGN_OUT -eq 1 ]]
then
    log "Done! To finish, please sign out and back in"
else
    log "Done!"
fi
