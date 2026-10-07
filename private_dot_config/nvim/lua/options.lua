vim.loader.enable()

-- Must be set before plugins load, or they bind to the wrong leader
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = true

vim.o.number = true
vim.o.mouse = 'a'
vim.o.showmode = false -- mode is in the statusline

-- Scheduled after UiEnter because the clipboard provider slows startup
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

vim.o.breakindent = true

-- Indentation: 2 spaces, never literal tabs.
--  guess-indent.nvim still overrides these per-file when it detects an existing style.
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2

vim.o.undofile = true

-- Case-insensitive search unless the term has a capital or \C
vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.o.inccommand = 'split' -- live preview of :s
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true -- ask to save instead of failing on :q with changes

-- vim: ts=2 sts=2 sw=2 et
