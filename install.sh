#!/usr/bin/env bash

set -e

sudo apt-get update
sudo apt-get install -yqq python3 curl

curl -s https://raw.githubusercontent.com/RVxLab/ubuntu-setup/master/setup.py | python3 - $@
