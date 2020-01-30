#!/bin/bash

set -e

# Files and locations
PROGRESS_FILE="/var/tmp/.ubuntu-setup-progress"
JETBRAINS_TOOLBOX_LOCATION="$HOME/jetbrains"
FONTS_LOCATION="$HOME/.fonts"

# Flags
IS_MINT=0
INSTALL_DOCKER=0
INSTALL_NVM=0
INSTALL_DAVFS=0
INSTALL_KEEPASSXC=0
INSTALL_FONTS=0
INSTALL_JETBRAINS_TOOLBOX=0
SHOULD_SIGN_OUT=0

while (( "$#" ))
do
    case "$1" in
        -r|--restart)
            rm "$PROGRESS_FILE"
            shift
            ;;
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
        --with-keepassxc)
            INSTALL_KEEPASSXC=1
            shift
            ;;
        --with-fonts)
            INSTALL_FONTS=1
            shift
            ;;
        --with-jetbrains-toolbox)
            INSTALL_JETBRAINS_TOOLBOX=1
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
    local PACKAGES=("neovim" "zsh" "git")

    if [[ $INSTALL_DOCKER -eq 1 ]]
    then
        PACKAGES+=("docker-ce" "docker-ce-cli" "containerd.io")
    fi

    if [[ $INSTALL_DAVFS -eq 1 ]]
    then
        PACKAGES+=("davfs2")
    fi

    if [[ $INSTALL_KEEPASSXC ]]
    then
        PACKAGES+=("keepassxc")
    fi

    echo "${PACKAGES[*]}"
}

# Install KeepassXC PPA
function installKeepassXCPPA {
    sudo add-apt-repository -y ppa:phoerious/keepassxc
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

    sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $DISTRO stable"
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

# Get vimrc contents
function getVimrc {
    local VIMRC
    VIMRC=$(cat <<EOF
"" PLUGINS
filetype indent plugin on

"" CONFIG

" Show line numbers
set number	                

" Break lines at word (requires Wrap lines)
set linebreak	                

" Wrap-broken line prefix
set showbreak=+++ 	        

" Line wrap (number of cols)
set textwidth=100	        

" Highlight matching brace
set showmatch	                

" Use visual bell (no beeping)
set visualbell	                

" Highlight all search results
set hlsearch	                

" Enable smart-case search
set smartcase	                

" Always case-insensitive
set ignorecase	                

" Searches for strings incrementally
set incsearch	                

" Auto-indent new lines
set autoindent	                

" Use spaces instead of tabs
set expandtab	                

" Number of auto-indent spaces
set shiftwidth=4	        

" Number of spaces per Tab
set softtabstop=4	        

" Show row and column ruler information
set ruler	                

" Number of undo levels
set undolevels=1000	        

" Backspace behaviour
set backspace=indent,eol,start	

" Enable syntax highlighting
set syntax=on                   
EOF
)

    echo "$VIMRC"
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

# set .vimrc/init.vim
function setVimrc {
    getVimrc > "$HOME/.vimrc"

    mkdir -p "$HOME/.config/nvim"
    ln -s "$HOME/.vimrc" "$HOME/.config/nvim/init.vim"
}

# Install prerequisites
function installPrerequisites {
    sudo apt-get -yqq update
    sudo apt-get -yqq install apt-transport-https ca-certificates curl gnupg-agent software-properties-common wget tar jq
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

# Install Jetbrains Toolbox
function installJetbrainsToolbox {
    TOOLBOX_TAR_FILE="$JETBRAINS_TOOLBOX_LOCATION/toolbox.tgz"

    mkdir -p "$JETBRAINS_TOOLBOX_LOCATION"
    wget -qO "$TOOLBOX_TAR_FILE" 'https://data.services.jetbrains.com/products/download?platform=linux&code=TBA'
    tar -C "$JETBRAINS_TOOLBOX_LOCATION" -xzf "$TOOLBOX_TAR_FILE"
    rm "$TOOLBOX_TAR_FILE"
}

# Install fonts
function installFonts {
    mkdir -p "$FONTS_LOCATION"
    wget -qO- https://api.github.com/repos/microsoft/cascadia-code/releases | jq -r '.[0].assets[] | select(.name == "Cascadia.ttf" or .name == "CascadiaPL.ttf") | .browser_download_url' | xargs wget -qP "$FONTS_LOCATION"
}

# Test if everything is in order
function ensureSuccess {
    if [[ $INSTALL_DOCKER -eq 1 ]]
    then
        command -v docker
    fi

    if [[ $INSTALL_NVM -eq 1 ]]
    then
        stat "$HOME/.nvm"
    fi

    if [[ $INSTALL_DAVFS -eq 1 ]]
    then
        command -v mount.davfs
    fi

    if [[ $INSTALL_KEEPASSXC -eq 1 ]]
    then
        command -v keepassxc
    fi

    if [[ $INSTALL_FONTS -eq 1 ]]
    then
        stat "$HOME/.fonts"
    fi

    if [[ $INSTALL_JETBRAINS_TOOLBOX -eq 1 ]]
    then
        EXPECTED_NAME="jetbrains-toolbox"
        ACTUAL_NAME=$(find "$JETBRAINS_TOOLBOX_LOCATION" -type f -exec basename {} \;)

        if [[ "$EXPECTED_NAME" != "$ACTUAL_NAME" ]]
        then
            echo "Failed to assert that Jetbrains Toolbox was installed properly in $JETBRAINS_TOOLBOX_LOCATION" 1>&2
        fi
    fi
}

CURRENT_PROGRESS=$(getProgress)

# Let's roll!
# Steps:
# 0 = Fresh run
# 1 = Prerequisites installed
# 2 = Docker PPA
# 3 = KeepassXC PPA
# 4 = Install packages
# 5 = Change shell to zsh
# 6 = Set up user groups
# 7 = Install oh my zsh
# 8 = Install nvm
# 9 = Install fonts
# 10 = Install Jetbrains Toolbox

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

# Install the KeepassXC PPA
if [[ $CURRENT_PROGRESS -eq 3 ]]
then
    if [[ $INSTALL_KEEPASSXC ]]
    then
        log "Adding KeepassXC PPA"
        installKeepassXCPPA
    fi

    setProgress 4
fi

# Install all packages
if [[ $CURRENT_PROGRESS -eq 4 ]]
then
    log "Installing packages"
    installPackages
    setProgress 5
fi

# Set shell to zsh
if [[ $CURRENT_PROGRESS -eq 5 ]]
then
    log "Setting shell to zsh"
    setShellZsh
    setShouldSignOut
    setProgress 6
fi

# Set up user groups
if [[ $CURRENT_PROGRESS -eq 6 ]]
then
    log "Setting up user groups"
    setupUserGroup
    setShouldSignOut
    setProgress 7
fi

# Set up ohmyzsh
if [[ $CURRENT_PROGRESS -eq 7 ]]
then
    log "Installing oh my zsh"
    installOhMyZsh
    setZshrc
    setProgress 8
fi

# Set up nvm
if [[ $CURRENT_PROGRESS -eq 8 ]]
then
    if [[ $INSTALL_NVM -eq 1 ]]
    then
        log "Installing nvm"
        installNvm
    fi

    setProgress 9
fi

# Add fonts
if [[ $CURRENT_PROGRESS -eq 9 ]]
then
    if [[ $INSTALL_FONTS -eq 1 ]]
    then
        log "Installing fonts"
        installFonts
    fi

    setProgress 10
fi

# Set up extra software
if [[ $CURRENT_PROGRESS -eq 10 ]]
then
    if [[ $INSTALL_JETBRAINS_TOOLBOX -eq 1 ]]
    then
        log "Installing Jetbrains Toolbox"
        installJetbrainsToolbox
    fi

    setProgress 11
fi

# Test if everything is good
log "Testing if everything is done properly"
ensureSuccess

# Exit message
if [[ $SHOULD_SIGN_OUT -eq 1 ]]
then
    log "Done! To finish, please sign out and back in"
else
    log "Done!"
fi
