# My Ubuntu (and derivatives) setup

## Software:

 - zsh + [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
 - vim + [SpaceVim](https://spacevim.org)

## Installation

Ensure you have the following installed:

 - zsh
 - vim
 - git

To install, run this:

Using wget:

```
wget -qO- https://raw.githubusercontent.com/RVxLab/ubuntu-setup/master/install.sh | bash
```

Using curl

```
curl -s -o- https://raw.githubusercontent.com/RVxLab/ubuntu-setup/master/install.sh | bash
```

## Updating

To update, simply go to `$HOME/.RVxLab/ubuntu-setup` and `git pull`, then run `run.sh`

## run.sh

`run.sh` is the main script.

```
run.sh
    -f  Force installation
```

If a file already exists, you'll be asked to overwrite it unless the `-f` flag is set.
