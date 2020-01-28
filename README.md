# My Ubuntu (and derivatives) setup

This is a script that sets up my Linux environments as I like it.

## Disclaimer

**Warning, this script overwrites your existing .zshrc file and adds groups to your current user.**

**This should only be ran on a fresh install.**

## Software:

 - zsh + [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
 - neovim
 - keepassxc (using --with-keepassxc)
 - docker (using --with-docker)
 - nvm (using --with-nvm)
 - davfs2 (using --with-davfs)

## Installation

To install:

```
wget -qO- https://raw.githubusercontent.com/RVxLab/ubuntu-setup/master/install.sh | bash
```

You can add flags by slightly changing the bash command at the end:

```
wget -qO- https://raw.githubusercontent.com/RVxLab/ubuntu-setup/master/install.sh | bash -s - --with-docker --with-nvm --with-davfs
```

### Options

```
-r|--restart
Restarts the installation by removing /var/tmp/.ubuntu-setup-progress

--with-docker
Install Docker, also adds your user to the docker group

--with-nvm
Install nvm

--with-davfs
Install davfs2, also adds your user to the davfs group

--with-keepassxc
Install the latest version of KeepassXC
```

## Tests

This script has been tested on Ubuntu 18.04 and Debian Buster.

I tested it to work locally on Linux Mint 19.3, but I can't find Docker images for that. It does work, as that is my OS of choice so naturally I'm making sure it works there.
