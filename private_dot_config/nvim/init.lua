-- Neovim configuration — based on kickstart-modular.nvim (vim.pack), made my own.
-- Load order matters: options → keymaps → vim.pack setup → plugins.

-- [[ Setting options ]]
require 'options'

-- [[ Basic Keymaps ]]
require 'keymaps'

-- [[ Set up vim.pack ]]
require 'pack'

-- [[ Configure and install plugins ]]
require 'plugins'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
