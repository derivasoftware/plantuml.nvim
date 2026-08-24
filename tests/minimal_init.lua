-- Headless harness: only this plugin on the runtimepath.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
-- tests must be immune to leftover swapfiles from crashed runs
vim.opt.swapfile = false
vim.opt.shortmess:append("A")
