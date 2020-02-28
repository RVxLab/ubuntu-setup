# My Ubuntu (and derivatives) setup

This is a script that sets up my Linux environments as I like it.

## Disclaimer

**Warning, this script overwrites your existing .zshrc file and adds groups to your current user.**

**This should only be ran on a fresh install.**

## Software:

 - zsh + [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
 - [micro](https://github.com/zyedidia/micro)
 - tilix
 - keepassxc (using --keepassxc)
 - docker (using --docker)
 - nvm (using --nvm)
 - davfs2 (using --davfs) (not working currently)
 - Jetbrains Toolbox (using --jetbrains)

### Other options
 - zsh-theme (Default: simple)
 - overwrite-zsh (Overwrites .zshrc when set)

## Installation

To install:

```
curl -s https://raw.githubusercontent.com/RVxLab/ubuntu-setup/master/install.sh | bash
```

You can add flags by slightly changing the bash command at the end:

```
curl -s https://raw.githubusercontent.com/RVxLab/ubuntu-setup/master/install.sh | bash -s - <flags>
```

## Tests

This script has been tested on Ubuntu 18.04 and Debian Buster.

I tested it to work locally on Linux Mint 19.3, but I can't find Docker images for that. It does work, as that is my OS of choice so naturally I'm making sure it works there.
