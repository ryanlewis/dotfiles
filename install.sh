#!/bin/zsh
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.dotfiles/prezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done

# Install some build stuff (YouCompleteMe needs this)
apt-get install -y build-essential cmake python-dev

# Install oh my zsh
curl -L http://install.ohmyz.sh | sh

# Install dotfiles
ln -s ~/.dotfiles/vim/vimrc ~/.vimrc
ln -s ~/.dotfiles/vim ~/.vim

# Remove zshrc, link to ours
rm ~/.zshrc
ln -s ~/.dotfiles/zshrc ~/.zshrc

# Init submodules 
git submodule update --init --recursive

# Install vim bundles
vim +PluginInstall +qall

# Compile YouCompleteMe
cd ~/.vim/bundle/YouCompleteMe
./install.sh
