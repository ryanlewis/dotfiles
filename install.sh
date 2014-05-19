#!/bin/zsh
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.dotfiles/prezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done

# Install oh my zsh
curl -L http://install.ohmyz.sh | sh

# Install dotfiles
ln -s ~/.dotfiles/vim/vimrc ~/.vimrc
ln -s ~/.dotfiles/vim ~/.vim

# Remove zshrc, link to ours
rm ~/.zshrc
ln -s ~/.dotfiles/zshrc ~/.zshrc

# Install vim bundles
vim +PluginInstall +qall
