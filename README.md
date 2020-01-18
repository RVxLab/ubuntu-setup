# My Ubuntu (and derivatives) setup

This is a script that sets up my Linux environments as I like it.

## Disclaimer

**Warning, this script overwrites your existing .zshrc file and adds groups to your current user.**

**This should only be ran on a fresh install.**

## Software:

 - zsh + [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
 - vim
 - keepassxc
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
