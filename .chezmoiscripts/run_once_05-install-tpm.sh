#!/bin/bash
# Install tmux plugin manager (TPM) - runs once
set -e

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ -d "$TPM_DIR" ]; then
  echo "TPM already installed"
  exit 0
fi

echo "Installing TPM..."
git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
echo "TPM installed. Run prefix + I inside tmux to install plugins."
