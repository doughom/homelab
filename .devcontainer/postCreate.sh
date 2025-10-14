#!/bin/bash -e

sudo sed -i "s/set compatible/set nocompatible/g" /etc/vim/vimrc.tiny

npm --prefix .devcontainer install

python -m venv venv
# shellcheck disable=SC1091
source venv/bin/activate
pip install --require-hashes -r .devcontainer/requirements.txt
pre-commit install --install-hooks

# Activate venv always
echo source venv/bin/activate >> "$HOME/.bashrc"
